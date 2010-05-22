require '../../lib/ruby/client'
class Injection < Riddl::Implementation
  def response
# {{{
    # Stop instance {{{
    # cpee_client = Riddl::Client.new(@p[1].value)
    # puts "stoping before trhead"
    # status, resp = cpee_client.resource("/properties/values/state").put [Riddl::Parameter::Simple.new("value", "stopping")]
    # }}}  
    Thread.new {
      Thread.pass; 
      begin
        analyze(@p[0].value, @p[1].value, @p[2].value);
      rescue Execption => e
        puts e.backtrace
      end
    }
    Riddl::Parameter::Simple.new("injecting", "true")
# }}}
  end

  def analyze(position, cpee_uri, rescue_uri)
  restart = false
  continue = true
# {{{ 
    begin
      cpee_client = Riddl::Client.new(cpee_uri)
      rescue_client = Riddl::Client.new(rescue_uri)
      injected = nil

    # Get description# {{{
    status, resp = cpee_client.resource("/properties/values/description").get
    if status != 200
      puts "Error receiving description at #{cpee_uri}/properties/values/description: #{status}"
      return
    end
    description = XML::Smart.string(resp[0].value.read)
    # }}}
    # Get call-node  and service_operation {{{ 
    call_node = description.find("//cpee:call[@id = '#{position}']", {"cpee" => "http://cpee.org/ns/description/1.0"}).first
    service_operation = call_node.find("descendant::cpee:serviceoperation", {"cpee" => "http://cpee.org/ns/description/1.0"}).first.text.gsub('"','')
    # }}}
    # Get resource-path {{{
    status, resp = cpee_client.resource("/properties/values/endpoints/#{call_node.attributes['endpoint']}").get
    if status != 200
      puts "Error receiving endpoint at #{cpee_uri}/properties/values/endpoints/#{call_node.attributes['endpoint']}: #{status}"
      return
    end
    resource_path = resp[0].value
    # }}}
     # Create injected-block {{{
    injected = description.root.add("injected")
    injected.attributes['source'] = call_node.attributes['id']
    # }}}
    # Check if injection is on class-level {{{
    class_level = true
    if(call_node.parent.name == 'injected')
      parent_so = description.find("//cpee:call[@id = '#{call_node.parent.attributes['source']}']//cpee:service/cpee:serviceoperation", {"cpee" => "http://cpee.org/ns/description/1.0"}).first.text
      class_level = false if parent_so.gsub('"','') == service_operation
    end
    # }}}
    if (class_level) 
      # Injecting class-level {{{
      puts " == Injecting operation #{service_operation} of domain #{resource_path.split('/')[0]}"
      # Move manipulate into seperate node, set result-attribute for injected and create output context-variable {{{
      man_block = call_node.find("child::cpee:manipulate", {"cpee" => "http://cpee.org/ns/description/1.0"}).first
      if man_block
        man_block.attributes['id'] = "man_block_from_#{call_node.attributes['id']}"
        man_block.attributes['context'] = "@result_#{call_node.attributes['id']}"
        injected.attributes['result'] = "@result_#{call_node.attributes['id']}"
        call_node.add_after(man_block)
#        man_block.find("child::*").delete_if! {true}
        injected.add("manipulate", {"id"=>"create_result_for_#{call_node.attributes['id']}"}, "context :\"result_#{call_node.attributes['id']}\" => Hash.new")
      end
      # }}}
      status, resp = rescue_client.resource("#{resource_path.split('/')[0]}/operations/#{service_operation}").get  # {{{
      if status != 200
        puts "Error receiving wf at #{rescue_uri}/#{resource_path.split('/')[0]}/operations/#{service_operation}: #{status}"
        return
      end # }}}
      injected.add(inject_class_level(XML::Smart.string(resp[0].value.read), call_node, cpee_client, rescue_client).children)
      # }}} 
    else 
      # Injection service-level {{{
      parallel = injected.add("parallel")
      add_service(parallel, resource_path, call_node, cpee_client, rescue_client)
      # }}} 
    end
    call_node.add_after(injected)
    # Set inject, description, position and re-start {{{
    status, resp = cpee_client.resource("/properties/values/description").put [Riddl::Parameter::Simple.new("value", description.root.dump)]
    puts "=== setting description #{status}"
    status, resp = cpee_client.resource("/properties/values/positions/#{call_node.attributes['id']}").put [Riddl::Parameter::Simple.new("value", "after")] if continue
    puts "=== setting position: #{status}"
    status, resp = cpee_client.resource("/properties/values/state").put [Riddl::Parameter::Simple.new("value", "running")] if restart
    puts "=== starting #{status}"
    # }}} 
    rescue => e
      puts $!
      puts e.backtrace
    end
# }}}
  end

  # renaming id's, endpoints, context, ....
  # return controlflow of injected wf
  def inject_class_level(wf, call_node, cpee_client, rescue_client)
# {{{
    # Change id's {{{
    wf.find("//@id").each {|a| a.value = call_node.attributes['id']+'__'+a.value}
    # }}}  
    # Change endpoints  {{{
    wf.find("//flow:endpoints/*", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).each do |node|
      cpee_client.resource("/properties/values/endpoints/").post [Riddl::Parameter::Simple.new("key", call_node.attributes['id']+'__'+node.name.name),
                                                                  Riddl::Parameter::Simple.new("value", node.text == nil ? "" : node.text)]
    end
    wf.find("//@endpoint").each do |a|
      a.value = a.value == "resource_path" ? call_node.attributes['endpoint'] : call_node.attributes['id']+'__'+a.value
    end
    # }}} 
    # Change context-variables: variables, test {{{
    wf.find("//flow:context-variables/*", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).each do |node|
      cpee_client.resource("/properties/values/context-variables/").post [Riddl::Parameter::Simple.new("key", call_node.attributes['id']+'__'+node.name.name),
                                                                  Riddl::Parameter::Simple.new("value", node.text)] if node.name != "resource_path"
    end
    wf.find("//@variable").each {|a| a.value = call_node.attributes['id']+'__'+a.value}
    wf.find("//@test").each {|a| a.value = call_node.attributes['id']+'__'+a.value}
    # }}}
    # Resovle message-parameter {{{
    wf.find("//flow:execute/descendant::flow:input[string(@message-parameter)]", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).delete_if! do |p|
      var =  call_node.find("child::cpee:parameters/cpee:parameters/cpee:#{p.attributes['message-parameter']}", {"cpee" => "http://cpee.org/ns/description/1.0"}).first
      temp = p.parent.add("input", {"name"=>p.attributes['name'], "variable"=>var.text}) if var
      puts "Variable named #{p.attributes['message-parameter']} could not be resolved" if not var
      true
    end
    wf.find("//flow:execute/descendant::flow:output[string(@message-parameter)]", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).each do |p|
      res_object = call_node.find("ancestor::cpee:injected[string(@result)]",{"cpee" => "http://cpee.org/ns/description/1.0"}).first
      if res_object 
        p.attributes['message-parameter'] = "#{call_node.parent.attributes['result']}[:\"#{resource_path.gsub("__","/")}\"][:#{p.attributes['message-parameter']}]"
      end
      puts "Ancestor Injected not found" if not res_object
    end
# }}}
    # Resolve messages input/output {{{ 
    wf.find("//flow:execute/descendant::flow:call/flow:input[string(@message)]", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).delete_if! do |p|
      wf.find("//d:message[@name = '#{p.attributes['message']}']/rng:element", {"d"=>"http://rescue.org/ns/domain/0.2", "rng"=>"http://relaxng.org/ns/structure/1.0"}).each do |e|
        value = call_node.find("child::cpee:parameters/cpee:parameters/cpee:#{e.attributes['name']}", {"cpee" => "http://cpee.org/ns/description/1.0"}).first
        p.add_after("input", {"name" => e.attributes['name'], "message-parameter" =>  value.text}) if value
      end
      true
    end
    wf.find("//flow:execute/descendant::flow:call/flow:output[string(@message)]", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).delete_if! do |p|
      wf.find("//d:message[@name = '#{p.attributes['message']}']/rng:element", {"d"=>"http://rescue.org/ns/domain/0.2", "rng"=>"http://relaxng.org/ns/structure/1.0"}).each do |e|
        var = call_node.find("child::cpee:manipulate/cpee:output[@message-parameter = '#{e.attributes['name']}']", {"cpee" => "http://cpee.org/ns/description/1.0"}).first
        if var
          p.add_after(var)
          man_block= call_node.find("child::cpee:manipulate", {"cpee" => "http://cpee.org/ns/description/1.0"}).first
#          man_block.text = "\n@#{var.attributes['variable']} = #{man_block.attributes['output']}[:#{var.attributes['message-parameter']}]"+man_block.text           
        end
      end
      true
    end
    # }}}
    # Add repositroy-information to new operation-calls {{{
    wf.find("//flow:execute/descendant::flow:call", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).each do |call|
      call.attributes['repository'] = call_node.find("string(child::cpee:parameters/cpee:service/cpee:repository)", {"cpee" => "http://cpee.org/ns/description/1.0"}).first
      call.attributes['resources'] = call_node.find("string(child::cpee:parameters/cpee:service/cpee:resources)", {"cpee" => "http://cpee.org/ns/description/1.0"}).first
      call.attributes['injection'] = call_node.find("string(child::cpee:parameters/cpee:service/cpee:injection)", {"cpee" => "http://cpee.org/ns/description/1.0"}).first
    end
    # }}}
    doc = wf.find("//flow:execute", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).first.to_doc
#puts doc
#puts XML::Smart.string(doc.transform_with(XML::Smart.open("rng+xsl/rescue2cpee.xsl")))
    XML::Smart.string(doc.transform_with(XML::Smart.open("rng+xsl/rescue2cpee.xsl"))).root
# }}}
  end

  # renaming id's, endpoints, context, ....
  # return controlflow of injected wf
  def inject_service_level(wf, call_node, cpee_client, resource_path)
# {{{
    resource_path.gsub!('/', '__')
    op = call_node.find("descendant::cpee:serviceoperation", {"cpee" => "http://cpee.org/ns/description/1.0"}).first.text.gsub('"','') 
    puts " == Injecting operation #{op} of service #{resource_path}"
    # Change id's {{{ 
    wf.find("//@id").each {|a| a.value = call_node.attributes['id']+'__'+resource_path+'__'+a.value}
    # }}}   
    # Change endpoints  {{{
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
    # Resovle message-parameter {{{
    wf.find("//flow:#{op}/descendant::flow:input[string(@message-parameter)]", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).delete_if! do |p|
      var =  call_node.find("child::cpee:parameters/cpee:parameters/cpee:#{p.attributes['message-parameter']}", {"cpee" => "http://cpee.org/ns/description/1.0"}).first
      temp = p.parent.add("input", {"name"=>p.attributes['name'], "variable"=>var.text}) if var
      puts "Variable named #{p.attributes['message-parameter']} could not be resolved" if not var
      true
    end
    wf.find("//flow:#{op}/descendant::flow:output[string(@message-parameter)]", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).each do |p|
      res_object = call_node.find("ancestor::cpee:injected[string(@result)]",{"cpee" => "http://cpee.org/ns/description/1.0"}).first
      if res_object 
        p.attributes['message-parameter'] = "#{call_node.parent.attributes['result']}[:\"#{resource_path.gsub("__","/")}\"][:#{p.attributes['message-parameter']}]"
      end
    end
# }}}
    doc = wf.find("//flow:#{op}/flow:execute", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).first.to_doc
    # The new doc seem's to have lost all namespace-information during document creation
    ns = doc.root.namespaces.add("flow","http://rescue.org/ns/controlflow/0.2")
    doc.find("//*").each { |node| node.namespace = ns }
#puts doc
#puts XML::Smart.string(doc.transform_with(XML::Smart.open("rng+xsl/rescue2cpee.xsl")))
    XML::Smart.string(doc.transform_with(XML::Smart.open("rng+xsl/rescue2cpee.xsl"))).root
#  }}}
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
      branch.add("manipulate", {"id"=>"result_for_#{call_node.attributes['id']}_service_#{resource_path.gsub("/","_")}"}, "#{call_node.parent.attributes['result']}[:\"#{resource_path}\"] = Hash.new")
      branch.add(inject_service_level(XML::Smart.string(resp[0].value.read), call_node, cpee_client, resource_path).children)
    end
    # }}}
  end
  
  def check_properties
    # {{{
    # }}}
  end

end