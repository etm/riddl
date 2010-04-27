require '../../lib/ruby/client'

class Injection < Riddl::Implementation
  def response
    #inject(@p[0].value, @p[1].value, @p[2].value)

    Thread.new {Thread.pass; analyze(@p[0].value, @p[1].value, @p[2].value);}
    Riddl::Parameter::Simple.new("injecting", "true")
  end

  def analyze(position, cpee_uri, rescue_uri)
    cpee_client = Riddl::Client.new(cpee_uri)
    rescue_client = Riddl::Client.new(rescue_uri)
    injected = nil

    #  Get description# {{{
    status, resp = cpee_client.resource("/properties/values/description").get
    if status != 200
      puts "Error receiving description at #{cpee_uri}/properties/values/description: #{status}"
      @status = 404
      return
    end
    description = XML::Smart.string(resp[0].value.read)
    # Get call-node
    call_node = description.find("//flow:call[@id = '#{position}']", {"flow" => "http://rescue.org/ns/controlflow/0.2"}).first
    # }}}

puts call_node.parent.name
puts call_node.parent.attributes['service-operation']
puts call_node.attributes['service-operation']
    
    # Stop instance
    status, resp = cpee_client.resource("/properties/values/state").put [Riddl::Parameter::Simple.new("value", "stopping")]
    puts "=== stopping #{status}"

    # Get resource-path# {{{
    status, resp = cpee_client.resource("/properties/values/endpoints/#{call_node.attributes['endpoint']}").get
    if status != 200
      puts "Error receiving endpoint at #{cpee_uri}/properties/values/endpoints/#{call_node.attributes['endpoint']}: #{status}"
      @status = 404
      return
    end
    resource_path = resp[0].value
    # }}}

     # Create injected-block# {{{
    injected = description.root.add("injected")
    call_node.attributes.each {|a| injected.attributes[a.name] = a.value}
    injected.add("interface")
    injected.children[0].add(call_node.children, XML::Smart::Dom::Element::COPY)
    # }}}

    if (call_node.parent.name != 'injected' && call_node.parent.attributes['service-operation'] != call_node.attributes['service-operation']) 
      # Injecting class-level {{{
      status, resp = rescue_client.resource("#{resource_path.split('/')[0]}/operations/#{call_node.attributes['service-operation']}").get
      if status != 200
        puts "Error receiving wf at #{rescue_uri}/#{resource_path.split('/')[0]}/operations/#{call_node.attributes['service-operation']}: #{status}"
        @status = 404
        return
      end
      puts "injecting"
      injected.add(inject_class_level(XML::Smart.string(resp[0].value.read), call_node, cpee_client))
      # }}} 
    else 
      # Injection instance-level {{{
      parallel = injected.add("parallel")
      add_service(parallel, resource_path, call_node, cpee_client, rescue_client)
      # }}}
    end
    
    # Set inject, description, position and re-start {{{
    call_node.add_after(injected)
    status, resp = cpee_client.resource("/properties/values/description").put [Riddl::Parameter::Simple.new("value", description.root.dump)]
    puts "=== setting description #{status}"
    status, resp = cpee_client.resource("/properties/values/positions/#{call_node.attributes['id']}").put [Riddl::Parameter::Simple.new("value", "after")]
    puts "=== setting position: #{status}"
    status, resp = cpee_client.resource("/properties/values/state").put [Riddl::Parameter::Simple.new("value", "running")]
    puts "=== starting #{status}"
    # }}} 
    
  end

  def add_service(parallel_node, resource_path, call_node, cpee_client, rescue_client)
    puts resource_path
    status, resp = rescue_client.resource(resource_path).get
    puts status
    return if status != 200
    if resp[0].name == "atom-feed"
      feed = XML::Smart.string(resp[0].value.read)
      feed.find("//a:entry/a:link", {"a"=>"http://www.w3.org/2005/Atom"}).each do |link|
        puts "searching at #{resource_path}/#{link.text}"
        add_service(parallel_node, "#{resource_path}/#{link.text}", call_node, cpee_client, rescue_client)
      end
    else
      branch = parallel_node.add("parallel_branch", {"pass"=>"", "local"=>""})
      puts "service-inject"
      branch.add(inject_service_level(XML::Smart.string(resp[0].value.read), call_node, cpee_client, resource_path))
    end
  end

  # renaming id's, endpoints, context, ....
  # return controlflow of injected wf
  def inject_class_level(wf, call_node, cpee_client)
    puts "ids"
    # Change id's {{{
    wf.find("//@id").each {|a| a.value = call_node.attributes['id']+'__'+a.value}
    # }}}  
    puts "eps"
    # Change endpoints  {{{
    wf.find("//flow:endpoints/*", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).each do |node|
      cpee_client.resource("/properties/values/endpoints/").post [Riddl::Parameter::Simple.new("key", call_node.attributes['id']+'__'+node.name.name),
                                                                  Riddl::Parameter::Simple.new("value", node.text == nil ? "" : node.text)] if node.name != "resource_path"
    end
    puts "eps2"
    wf.find("//@endpoint").each do |a|
      a.value = a.value == "resource_path" ? call_node.attributes['endpoint'] : call_node.attributes['id']+'__'+a.value
    end
    # }}} 
    puts "ctx"
    # Change context-variables: variables, test {{{
    wf.find("//flow:context-variables/*", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).each do |node|
      cpee_client.resource("/properties/values/context-variables/").post [Riddl::Parameter::Simple.new("key", call_node.attributes['id']+'__'+node.name.name),
                                                                  Riddl::Parameter::Simple.new("value", node.text)]
    end
    wf.find("//@variable").each {|a| a.value = call_node.attributes['id']+'__'+a.value}
    wf.find("//@test").each {|a| a.value = call_node.attributes['id']+'__'+a.value}
    # }}}
    puts "repo-ep"
    # Add repositroy-node to new operation-calls {{{
    repo_ep = nil
    wf.find("//flow:call[string(@service-operation)]", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).each do |node|
      repo_ep =  call_node.find("child::flow:repository", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).first.attributes['endpoint'] if repo_ep == nil
      node.add("repository", {"endpoint"=> repo_ep})
    end
    # }}}
    wf.find("//flow:#{call_node.attributes['state-controlflow']}/*", {"flow"=>"http://rescue.org/ns/controlflow/0.2"})
  end

  # renaming id's, endpoints, context, ....
  # return controlflow of injected wf
  def inject_service_level(wf, call_node, cpee_client, resource_path)
    resource_path.gsub!('/', '__')
    puts "ids"
    # Change id's {{{ 
    wf.find("//@id").each {|a| a.value = call_node.attributes['id']+'__'+resource_path+'__'+a.value}
    # }}}   
    puts "eps"
    # Change e ndpoints  {{{
    puts "ep -> service-level: #{call_node.attributes['id']}"
    wf.find("//flow:#{call_node.attributes['service-operation']}/flow:endpoints/*", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).each do |node|
      puts "ep -> service-level: #{call_node.attributes['id']+'__'+node.name.name}"
      cpee_client.resource("/properties/values/endpoints/").post [Riddl::Parameter::Simple.new("key", call_node.attributes['id']+'__'+resource_path+'__'+node.name.name),
                                                                  Riddl::Parameter::Simple.new("value", node.text == nil ? "" : node.text)] if node.name != "resource_path"
    end
    wf.find("//@endpoint").each do |a|
      a.value = a.value == "resource_path" ? call_node.attributes['endpoint'] : call_node.attributes['id']+'__'+resource_path+'__'+a.value
    end
    # }}} 
    puts "ctx"
    # Change context-variables: variables, test {{{ 
    wf.find("//flow:#{call_node.attributes['service-operation']}/flow:context-variables/*", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).each do |node|
      cpee_client.resource("/properties/values/context-variables/").post [Riddl::Parameter::Simple.new("key", call_node.attributes['id']+'__'+resource_path+'__'+node.name.name),
                                                                  Riddl::Parameter::Simple.new("value", node.text)]
    end
    wf.find("//@variable").each {|a| a.value = call_node.attributes['id']+'__'+resource_path+'__'+a.value}
    wf.find("//@test").each {|a| a.value = call_node.attributes['id']+'__'+resource_path+'__'+a.value}
    # }}}
    wf.find("//flow:#{call_node.attributes['service-operation']}/flow:#{call_node.attributes['state-controlflow']}/*", {"flow"=>"http://rescue.org/ns/controlflow/0.2"})
  end
end
