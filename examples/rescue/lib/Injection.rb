require '../../lib/ruby/client'
class Injection < Riddl::Implementation
  def response
#    analyze(@p[0].value, @p[1].value, @p[2].value)
    if @p[1].value == 'none' 
      status, resp = Riddl::Client.new("http://localhost:9290/groups").resource("#{@p[2].value}/operations/#{@p[0].value}").get
      part = XML::Smart.string(resp[0].value.read)
      puts part
      Riddl::Parameter::Complex.new("xml", "text/xml",part.transform_with(XML::Smart.open("rng+xsl/rescue2cpee.xsl")))
    else
      Thread.new {
        Thread.pass; 
        begin
          analyze(@p[0].value, @p[1].value, @p[2].value);
        rescue Execption => e
          puts e.backtrace
        end
      }
      Riddl::Parameter::Simple.new("injecting", "true")
    end
  end

  def analyze(position, cpee_uri, rescue_uri)
    begin
    cpee_client = Riddl::Client.new(cpee_uri)

    # Stop instance {{{
    status, resp = cpee_client.resource("/properties/values/state").put [Riddl::Parameter::Simple.new("value", "stopping")]
    puts "=== stopping #{status}" 
    stopped = false
    until stopped
      status, resp = cpee_client.resource("/properties/values/state").get
      stopped = true if resp[0].value == "stopped"
      puts "state: #{resp[0].value}"
      sleep(1) if not stopped
    end
    # }}}

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
    # }}}
    # Get call-node {{{ 
    call_node = description.find("//cpee:call[@id = '#{position}']", {"cpee" => "http://cpee.org/ns/description/1.0"}).first
    service_operation = call_node.find("descendant::cpee:serviceoperation", {"cpee" => "http://cpee.org/ns/description/1.0"}).first.text.gsub('"','')
    # }}}
    # Get resource-path {{{
    status, resp = cpee_client.resource("/properties/values/endpoints/#{call_node.attributes['endpoint']}").get
    if status != 200
      puts "Error receiving endpoint at #{cpee_uri}/properties/values/endpoints/#{call_node.attributes['endpoint']}: #{status}"
      @status = 404
      return
    end
    resource_path = resp[0].value
    # }}}
     # Create injected-block {{{
    injected = description.root.add("injected")
    call_node.attributes.each {|a| injected.attributes[a.name] = a.value}
    injected.add("interface")
    injected.children[0].add(call_node.children, XML::Smart::Dom::Element::COPY)
    # }}}

    # Check if injection is on class-level {{{
    class_level = true
    if(call_node.parent.name == 'injected')
      parent_so = call_node.parent.find("child::cpee:interface//cpee:serviceoperation",  {"cpee" => "http://cpee.org/ns/description/1.0"}).first.text
      puts " === INJECTED:"
      puts "Parent-so: #{parent_so.gsub('"','')}"
      puts "Call-Node-SO: #{service_operation}"
      class_level = false if parent_so.gsub('"','') == service_operation
    end
    # }}}

    if (class_level) 
      # Injecting class-level {{{
      status, resp = rescue_client.resource("#{resource_path.split('/')[0]}/operations/#{service_operation}").get
      if status != 200
        puts "Error receiving wf at #{rescue_uri}/#{resource_path.split('/')[0]}/operations/#{service_operation}: #{status}"
        @status = 404
        return
      end
      injected.add(inject_class_level(XML::Smart.string(resp[0].value.read), call_node, cpee_client).children)
      # }}} 
    else 
      # Injection service-level {{{
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
  rescue => e
    puts $!
    puts e.backtrace
    end
  end

  def add_service(parallel_node, resource_path, call_node, cpee_client, rescue_client)
    # {{{ 
    status, resp = rescue_client.resource(resource_path).get
    return if status != 200
    if resp[0].name == "atom-feed"
      feed = XML::Smart.string(resp[0].value.read)
      feed.find("//a:entry/a:link", {"a"=>"http://www.w3.org/2005/Atom"}).each do |link|
        add_service(parallel_node, "#{resource_path}/#{link.text}", call_node, cpee_client, rescue_client)
      end
    else
      branch = parallel_node.add("parallel_branch")
      branch.add(inject_service_level(XML::Smart.string(resp[0].value.read), call_node, cpee_client, resource_path).children)
    end
    # }}}
  end

  # renaming id's, endpoints, context, ....
  # return controlflow of injected wf
  def inject_class_level(wf, call_node, cpee_client)
    # Change id's {{{
    wf.find("//@id").each {|a| a.value = call_node.attributes['id']+'__'+a.value}
    # }}}  
    # Change endpoints  {{{
    wf.find("//flow:endpoints/*", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).each do |node|
      cpee_client.resource("/properties/values/endpoints/").post [Riddl::Parameter::Simple.new("key", call_node.attributes['id']+'__'+node.name.name),
                                                                  Riddl::Parameter::Simple.new("value", node.text == nil ? "" : node.text)] if node.name != "resource_path"
    end
    wf.find("//@endpoint").each do |a|
      a.value = a.value == "resource_path" ? call_node.attributes['endpoint'] : call_node.attributes['id']+'__'+a.value
    end
    # }}} 
    # Change context-variables: variables, test {{{
    wf.find("//flow:context-variables/*", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).each do |node|
      cpee_client.resource("/properties/values/context-variables/").post [Riddl::Parameter::Simple.new("key", call_node.attributes['id']+'__'+node.name.name),
                                                                  Riddl::Parameter::Simple.new("value", node.text)]
    end
    wf.find("//@variable").each {|a| a.value = call_node.attributes['id']+'__'+a.value}
    wf.find("//@test").each {|a| a.value = call_node.attributes['id']+'__'+a.value}
    # }}}
    # Add repositroy-node to new operation-calls {{{
    wf.find("//flow:execute/flow:call", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).each do |call|
      call.attributes['repository'] = call_node.find("string(child::cpee:parameters/cpee:service/cpee:repository)", {"cpee" => "http://cpee.org/ns/description/1.0"}).first
      call.attributes['resources'] = call_node.find("string(child::cpee:parameters/cpee:service/cpee:resources)", {"cpee" => "http://cpee.org/ns/description/1.0"}).first
      call.attributes['injection'] = call_node.find("string(child::cpee:parameters/cpee:service/cpee:injection)", {"cpee" => "http://cpee.org/ns/description/1.0"}).first
    end
    # }}}
    doc = wf.find("//flow:execute", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).first.to_doc
    XML::Smart.string(doc.transform_with(XML::Smart.open("rng+xsl/rescue2cpee.xsl"))).root
  end

  # renaming id's, endpoints, context, ....
  # return controlflow of injected wf
  def inject_service_level(wf, call_node, cpee_client, resource_path)
    resource_path.gsub!('/', '__')
    # Change id's {{{ 
    wf.find("//@id").each {|a| a.value = call_node.attributes['id']+'__'+resource_path+'__'+a.value}
    # }}}   
    # Change e ndpoints  {{{
    op = call_node.find("descendant::cpee:serviceoperation", {"cpee" => "http://cpee.org/ns/description/1.0"}).first.text.gsub('"','') 
    wf.find("//flow:#{op}/flow:endpoints/*", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).each do |node|
      cpee_client.resource("/properties/values/endpoints/").post [Riddl::Parameter::Simple.new("key", call_node.attributes['id']+'__'+resource_path+'__'+node.name.name),
                                                                  Riddl::Parameter::Simple.new("value", node.text == nil ? "" : node.text)] if node.name != "resource_path"
    end
    wf.find("//@endpoint").each do |a|
      a.value = a.value == "resource_path" ? call_node.attributes['endpoint'] : call_node.attributes['id']+'__'+resource_path+'__'+a.value
    end
    # }}} 
    # Change context-variables: variables, test {{{ 
    wf.find("//flow:#{op}/flow:context-variables/*", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).each do |node|
      cpee_client.resource("/properties/values/context-variables/").post [Riddl::Parameter::Simple.new("key", call_node.attributes['id']+'__'+resource_path+'__'+node.name.name),
                                                                  Riddl::Parameter::Simple.new("value", node.text)]
    end
    wf.find("//@variable").each {|a| a.value = call_node.attributes['id']+'__'+resource_path+'__'+a.value}
    wf.find("//@test").each {|a| a.value = call_node.attributes['id']+'__'+resource_path+'__'+a.value}
    # }}}
    doc = wf.find("//flow:#{op}/flow:execute", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).first.to_doc
    # Teh new doc seem's to have lost all namespace-information during document creation
    ns = doc.root.namespaces.add("flow","http://rescue.org/ns/controlflow/0.2")
    doc.find("//*").each { |node| node.namespace = ns }
    XML::Smart.string(doc.transform_with(XML::Smart.open("rng+xsl/rescue2cpee.xsl"))).root
  end
end
