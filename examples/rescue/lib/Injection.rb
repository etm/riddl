require '../../lib/ruby/client'

class Injection < Riddl::Implementation
  def response
    #inject(@p[0].value, @p[1].value, @p[2].value)

    Thread.new {Thread.pass; inject(@p[0].value, @p[1].value, @p[2].value);}
    Riddl::Parameter::Simple.new("injecting", "true")
  end

  def inject(position, cpee_uri, rescue_uri)
    cpee_client = Riddl::Client.new(cpee_uri)
    rescue_client = Riddl::Client.new(rescue_uri)

    # Stop instance
    status, resp = cpee_client.resource("/properties/values/state").put [Riddl::Parameter::Simple.new("value", "stopping")]
    puts "=== stopping #{status}"
    # Get description# {{{
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

    # Get wf# {{{ 
    status, resp = rescue_client.resource("#{resource_path.split('/')[0]}/operations/#{call_node.attributes['service-operation']}").get
    if status != 200
      puts "Error receiving wf at #{rescue_uri}/#{resource_path.split('/')[0]}/operations/#{call_node.attributes['service-operation']}: #{status}"
      @status = 404
      return
    end
    wf = XML::Smart.string(resp[0].value.read)
    #puts wf
# }}}
    
    # Adapt wf 
    # Change id's {{{
    wf.find("//@id").each {|a| a.value = call_node.attributes['id']+'__'+a.value}
# }}} 

    # Change endpoints # {{{
    wf.find("//flow:endpoints/*", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).each do |node|
      cpee_client.resource("/properties/values/endpoints/").post [Riddl::Parameter::Simple.new("key", call_node.attributes['id']+'__'+node.name.name),
                                                                  Riddl::Parameter::Simple.new("value", node.text == nil ? "" : node.text)] if node.name != "resource_path"
    end
    wf.find("//@endpoint").each do |a|
      a.value = a.value == "resource_path" ? call_node.attributes['endpoint'] : call_node.attributes['id']+'__'+a.value
    end
# }}} 

    # Change context-variables: variables, test,# {{{
    wf.find("//flow:context-variables/*", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).each do |node|
      cpee_client.resource("/properties/values/context-variables/").post [Riddl::Parameter::Simple.new("key", call_node.attributes['id']+'__'+node.name.name),
                                                                  Riddl::Parameter::Simple.new("value", node.text)]
    end
    wf.find("//@variable").each {|a| a.value = call_node.attributes['id']+'__'+a.value}
    wf.find("//@test").each {|a| a.value = call_node.attributes['id']+'__'+a.value}
# }}}

    # Add repositroy-node to new operation-calls# {{{
    repo_ep = nil
    wf.find("//flow:call[string(@service-operation)]", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).each do |node|
      repo_ep =  call_node.find("child::flow:repository", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).first.attributes['endpoint'] if repo_ep == nil
      node.add("repository", {"endpoint"=> repo_ep})
    end
# }}}

    #Inject wf # {{{
    injected.add(wf.find("//flow:#{call_node.attributes['state-controlflow']}/*", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}))
    call_node.add_after(injected)
# }}}

#puts description

    
    # Set description
    status, resp = cpee_client.resource("/properties/values/description").put [Riddl::Parameter::Simple.new("value", description.root.dump)]
    puts "=== seting description #{status}"
    # Re-start instance
    status, resp = cpee_client.resource("/properties/values/state").put [Riddl::Parameter::Simple.new("value", "running")]
    puts "=== starting #{status}"
  end
end
