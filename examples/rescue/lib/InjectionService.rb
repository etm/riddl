require '../../lib/ruby/client'

class InjectionService < Riddl::Implementation
  def response  #{{{
    puts "== Injection-service: injecting position #{@p.value('position')} on instance #{@p.value('instance')}"
    pos, state =  analyze(@p.value('position'), @p.value('instance'))
    [Riddl::Parameter::Simple.new('position', pos), Riddl::Parameter::Simple.new('state', state)]
  end# }}} 

  def analyze(position, instance)# {{{ 
    new_position = nil
    new_state = nil
    begin
      injected = nil
      cpee_client = Riddl::Client.new(instance)
    # Get description {{{
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
      status, resp = cpee_client.resource("properties/values/endpoints/#{call_node.attributes['endpoint']}").get 
      puts "ERROR receiving endpoint named #{call_node.attributes['endpoint']}" unless status == 200
      rescue_uri = XML::Smart.string(resp.value('value').read).root.text
      rescue_client = Riddl::Client.new(rescue_uri)
      # }}} 
    # Create injected-block {{{
    injected = description.root.add("injected")
    injected.attributes['source'] = call_node.attributes['id']
     # }}}
    # Check if injection is on class-level {{{
    class_level = true
    parent_injected = call_node.find('ancestor::cpee:injected', {"cpee" => "http://cpee.org/ns/description/1.0"}).last
    if(parent_injected)
      parent_so = description.find("//cpee:call[@id = '#{parent_injected.attributes['source']}']//cpee:service/cpee:serviceoperation", {"cpee" => "http://cpee.org/ns/description/1.0"}).first
      if parent_so
        class_level = false if parent_so.text.gsub('"','') == service_operation
      end
    end
    # }}}
      first_ancestor_loop = call_node.find("ancestor::cpee:loop", {"cpee" => "http://cpee.org/ns/description/1.0"}).first
      if (class_level) 
        # Injecting class-level {{{
        puts " == Injecting operation #{service_operation} of domain #{rescue_uri}"
        status, resp = rescue_client.resource("operations/#{service_operation}").get [] # {{{
        if status != 200
          puts "Error receiving description at #{rescue_uri}/operations/#{service_operation}: #{status}"
          return
        end # }}}
        wf = XML::Smart.string(resp[0].value.read)
        injected.add(call_node.find("child::cpee:constraints", {"cpee" => "http://cpee.org/ns/description/1.0"}), XML::Smart::Dom::Element::COPY)
        puts "INJECTING"*10
        puts call_node.dump
        puts "INJECTING"*10
        sub_controlflow = inject_class_level(wf, call_node, injected).children
        injected.add(sub_controlflow)
        if first_ancestor_loop.nil?
          man_block = call_node.find("child::cpee:manipulate", {"cpee" => "http://cpee.org/ns/description/1.0"}).first
          if man_block # Move manipulate into seperate node, set result-attribute for injected and create output context-variable {{{
            man_block.attributes['id'] = "manipulate_from_#{call_node.attributes['id']}"
            man_block.attributes['context'] = "context.result_#{call_node.attributes['id']}"
            injected.attributes['result'] = "context.result_#{call_node.attributes['id']}"
            man_block.attributes['properties'] = "#{injected.attributes['properties']}"
            call_node.add_after(man_block)
            man_block.add_after(injected.find("child::cpee:manipulate[@id = 'delete_objects_of_#{call_node.attributes['id']}']", {"cpee"=>"http://cpee.org/ns/description/1.0"})) # move del-blockt o last position (after man-block of call)
          end  # }}}
          call_node.add_after(injected)
        else
          puts "== Loop-Class-Injection =="*5
          puts "== Loop-Class-Injection =="*5
        end
      # }}}
      else 
        # Injection service-level {{{ 
        parallel = injected.add("parallel", {"generated"=>"true"})
        prop = call_node.find("ancestor::cpee:injected", {"cpee" => "http://cpee.org/ns/description/1.0"}).last.attributes['properties']
        injected.attributes['properties'] = "#{prop}[:\"#{call_node.attributes['oid']}\"]"
        if first_ancestor_loop.nil?
          add_service(parallel, rescue_client, call_node, cpee_client, "", parent_injected)
          call_node.add_after(injected)
        else
          puts "== Loop-Instance-Injection =="*5
          puts "== Loop-Instance-Injection =="*5
        end
        # }}} 
      end
      new_position = call_node.attributes['id']
      new_state = 'after'
      # Set description {{{
      puts "Setting description to instance"
      status, resp = cpee_client.resource("/properties/values/description").put [Riddl::Parameter::Simple.new("content", "<content>#{description.root.dump}</content>")]
      puts "=== setting description #{status}"
      # }}} 
      puts "\t\t\t\t\t New Position: #{new_position}"
      puts "\t\t\t\t\t New State: #{new_state}"
      [new_position, new_state]
    rescue => e
      puts $!
      puts e.backtrace
    end
  end# }}}

  def inject_class_level(wf, call_node, injected) # {{{
    man_text = "context.result_#{call_node.attributes['id']} = RescueHash.new\n"
    man_text_del = "context.delete(:\"result_#{call_node.attributes['id']}\")\n"
    # Create Property-Objects {{{
    prop = call_node.find("ancestor::cpee:injected", {"cpee" => "http://cpee.org/ns/description/1.0"}).last
    if prop.nil?
      prop = "context.properties_#{call_node.attributes['id']}"
      man_text << "#{prop} = RescueHash.new\n"
      man_text_del << "context.delete(:\"#{prop.split('.')[1]}\")\n"
    else
      prop = "#{prop.attributes['properties']}[:\"#{call_node.attributes['oid']}\"]"
    end
    injected.attributes['properties'] = prop
    wf.find("//flow:execute/descendant::flow:call[@service-operation]", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).each do |call|
      c = "#{prop}[:\"#{call.attributes.include?('oid') ? call.attributes['oid'] : call.attributes['id'] }\"]"
      man_text << "#{c} = RescueHash.new\n"
    end  #}}}
    # Change id's {{{
    wf.find("//@id").each do |a| 
      a.element.attributes['oid'] = a.value if not a.element.attributes.include?('oid')
      a.value = call_node.attributes['id']+'__'+a.value
    end  # }}}  
    # Change endpoints  {{{
    wf.find("//flow:endpoints/*", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).each do |node|
      man_text << "endpoints.#{call_node.attributes['id']+'__'+node.name.name} = \"#{node.text.nil? ? node.text : ""}\"\n"
      man_text_del << "endpoints.delete(:\"#{call_node.attributes['id']+'__'+node.name.name}\")\n"
    end
    wf.find("//flow:call", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).each do |a|
      if a.attributes.include?('endpoint-type') and a.attributes['endpoint-type'] == "outside"
        ep = call_node.find("child::cpee:parameters/cpee:additional_endpoints/cpee:#{a.attributes['endpoint']}", {"cpee" => "http://cpee.org/ns/description/1.0"}).first.text
        a.attributes['endpoint'] = ep.gsub('"', "")
      else
        a.attributes['endpoint'] = a.attributes['endpoint'] == "resource_path" ? call_node.attributes['endpoint'] : call_node.attributes['id']+'__'+a.attributes['endpoint']
      end
    end
    wf.find("//flow:call/@wsdl", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).each do |a|
      a.value = call_node.attributes['id']+'__'+a.value
    end
    wf.find("//flow:call/flow:resource-id", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).each do |a|
      if a.attributes.include?('endpoint-type') and a.attributes['endpoint-type'] == "outside"
        ep = call_node.find("child::cpee:parameters/cpee:additional_endpoints/cpee:#{a.attributes['endpoint']}", {"cpee" => "http://cpee.org/ns/description/1.0"}).first.text
        a.attributes['endpoint'] = ep.gsub('"', "")
      else
        a.attributes['endpoint'] = a.attributes['endpoint'] == "resource_path" ? call_node.attributes['endpoint'] : call_node.attributes['id']+'__'+a.attributes['endpoint']
      end
    end  # }}} 
    # Change context-variables: variables, test, context (within manipulate) {{{
    wf.find("//flow:context-variables/*", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).each do |node|
      if node.attributes.include?('class')
        man_text << "context.#{call_node.attributes['id']+'__'+node.name.name} = #{node.attributes['class']}\n"
      else
        man_text << "context.#{call_node.attributes['id']+'__'+node.name.name} = #{node.text.empty? ? "''" : node.text}\n"
      end
      man_text_del << "context.delete(:\"#{call_node.attributes['id']+'__'+node.name.name}\")\n"
    end
    wf.find("//@variable").each {|a| a.value = "context.#{call_node.attributes['id']}__#{a.value}"} 
    wf.find("//@test").each {|a| a.value = "context.#{call_node.attributes['id']}__#{a.value}"}
    wf.find("//@context").each {|a| a.value = "context.#{call_node.attributes['id']}__#{a.value}"}
    wf.find("//@input-parameter").each do |a| 
      p = call_node.find("child::cpee:parameters/cpee:parameters/cpee:#{a.value}", {"cpee" => "http://cpee.org/ns/description/1.0"}).first
      a.value = p.text if not p.nil?
      puts "Variable for manipulate-block #{a.parent.parent.attributes['id']} named #{a.value} not found" if p.nil?
    end
    wf.find("//@output-parameter").each do |a|
      a.value = "context.result_#{call_node.attributes['id']}[:#{a.value}]"
    end # }}}
    # Resovle message-parameter {{{
    wf.find("//flow:execute/descendant::flow:input[string(@message-parameter)]", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).delete_if! do |p|
      var =  call_node.find("child::cpee:parameters/cpee:parameters/cpee:#{p.attributes['message-parameter']}", {"cpee" => "http://cpee.org/ns/description/1.0"}).first
      temp = p.parent.add("input", {"name"=>p.attributes['name'], "variable"=>var.text}) if var
      puts "Variable named #{p.attributes['message-parameter']} could not be resolved" if not var
      true
    end
    done = Hash.new
    wf.find("//flow:execute/descendant::flow:output[string(@message-parameter)]", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).each do |output|
      call = output.parent
      res_object = call_node.find("ancestor::cpee:injected[string(@result)]",{"cpee" => "http://cpee.org/ns/description/1.0"}).last
      str = res_object.nil? ? "context.result_#{call_node.attributes['id']}" : "#{res_object.attributes['result']}"
      output.attributes['message-parameter'] = "#{str}[:#{output.attributes['message-parameter']}]"
    end # }}}
    # Add repositroy-information to new operation-calls {{{
    wf.find("//flow:execute/descendant::flow:call", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).each do |call|
      call.attributes['injection_handler'] = call_node.find("string(child::cpee:parameters/cpee:service/cpee:injection_handler)", {"cpee" => "http://cpee.org/ns/description/1.0"}).first
    end # }}}
    doc = wf.find("//flow:execute", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).first.to_doc
    injected.add("manipulate", {"id"=>"create_objects_for_#{call_node.attributes['id']}", "generated"=>"true"}, man_text)
    injected.add("manipulate", {"id"=>"delete_objects_of_#{call_node.attributes['id']}", "generated"=>"true"}, man_text_del)
    XML::Smart.string(doc.transform_with(XML::Smart.open("rng+xsl/rescue2cpee.xsl"))).root 
  end# }}}

   def inject_service_level(wf, call_node, resource_path, branch, parent_injected)# {{{
    man_text = "#{parent_injected.attributes['result']}[:\"#{resource_path}\"] = RescueHash.new #here\n"
    man_text_delete = ""
    index = resource_path.gsub("/","_").gsub(":","_")
    op = call_node.find("descendant::cpee:serviceoperation", {"cpee" => "http://cpee.org/ns/description/1.0"}).first.text.gsub('"','') 
    puts " == Injecting operation #{op} of service #{resource_path}"
    # Change id's {{{ 
    wf.find("//@id").each {|a| a.value = call_node.attributes['id']+'__'+index+'__'+a.value} # }}}   
    # Change endpoints  {{{
    wf.find("//flow:#{op}/flow:endpoints/*", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).each do |node|
      man_text << "endpoints.#{ call_node.attributes['id']+'__'+index+'__'+node.name.name} = \"#{node.text.nil? ? '' : node.text}\"\n"
      man_text_delete << "endpoints.delete(:\"#{ call_node.attributes['id']+'__'+index+'__'+node.name.name}\")\n"
    end
    wf.find("//@endpoint").each do |a|
      a.value = call_node.attributes['id']+'__'+index+'__'+a.value
    end # }}} 
    wf.find("//flow:call/@wsdl", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).each do |a|
      a.value = call_node.attributes['id']+'__'+index+'__'+a.value
    end
    # Change context-variables: variables, test {{{ 
    wf.find("//flow:#{op}/flow:context-variables/*", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).each do |node|
      if node.attributes.include?('class')
        man_text << "context.#{call_node.attributes['id']+'__'+index+'__'+node.name.name} = #{node.attributes['class']}\n" 
      else
        man_text << "context.#{call_node.attributes['id']+'__'+index+'__'+node.name.name} = \"#{node.text.empty? ? "''" : node.text}\"\n"
      end
      man_text_delete << "context.delete(:\"#{call_node.attributes['id']+'__'+index+'__'+node.name.name}\")\n"
    end
    wf.find("//flow:#{op}/descendant::flow:*/@variable",{"flow"=>"http://rescue.org/ns/controlflow/0.2"}).each {|a| a.value = "context.#{call_node.attributes['id']}__#{index}__#{a.value}"}
    wf.find("//flow:#{op}/descendant::flow:*/@test",{"flow"=>"http://rescue.org/ns/controlflow/0.2"}).each {|a| a.value = "context.#{call_node.attributes['id']}__#{index}__#{a.value}"}
    wf.find("//flow:#{op}/descendant::flow:*/@context",{"flow"=>"http://rescue.org/ns/controlflow/0.2"}).each {|a| a.value = "context.#{call_node.attributes['id']}__#{index}__#{a.value}"}
    wf.find("//flow:#{op}/descendant::flow:*/@input-parameter",{"flow"=>"http://rescue.org/ns/controlflow/0.2"}).each do |a| 
      p = call_node.find("child::cpee:parameters/cpee:parameters/cpee:#{a.value}", {"cpee" => "http://cpee.org/ns/description/1.0"}).first
      a.value = p.text if not p.nil?
      puts "Variable for manipulate-block #{a.element.parent.attributes['id']} named #{a.value} not found" if p.nil?
    end
    wf.find("//flow:#{op}/descendant::flow:*/@output-parameter",{"flow"=>"http://rescue.org/ns/controlflow/0.2"}).each do |a|
      res_object = call_node.find("ancestor::cpee:injected[string(@result)]",{"cpee" => "http://cpee.org/ns/description/1.0"}).last
      a.value = "#{parent_injected.attributes['result']}[:\"#{resource_path}\"][:#{a.value}]" if not res_object.nil?
    end # }}}
    # Resovle message-parameter {{{
    wf.find("//flow:#{op}/descendant::flow:input[string(@message-parameter)]", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).delete_if! do |p|
      var =  call_node.find("child::cpee:parameters/cpee:parameters/cpee:#{p.attributes['message-parameter']}", {"cpee" => "http://cpee.org/ns/description/1.0"}).first
      temp = p.parent.add("input", {"name"=>p.attributes['name'], "variable"=>var.text}) if var
      puts "Variable named #{p.attributes['message-parameter']} could not be resolved" if not var
      true
    end
    wf.find("//flow:#{op}/descendant::flow:output[string(@message-parameter)]", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).each do |p|
      res_object = call_node.find("ancestor::cpee:injected[string(@result)]",{"cpee" => "http://cpee.org/ns/description/1.0"}).last
      p.attributes['message-parameter'] = "#{parent_injected.attributes['result']}[:\"#{resource_path}\"][:#{p.attributes['message-parameter']}]" if not res_object.nil?
    end # }}}
     # Create and fill properties-object {{{ 
    prop = call_node.find("ancestor::cpee:injected", {"cpee" => "http://cpee.org/ns/description/1.0"}).last.attributes['properties']
    prop_code = ""
    prop_code << "#{prop}[:\"#{call_node.attributes['oid']}\"][:\"#{resource_path}\"] = RescueHash.new\n"
    prop_code << fill_properties(wf.find("//p:properties", {"p"=>"http://rescue.org/ns/properties/0.2"}).first, "#{prop}[:\"#{call_node.attributes['oid']}\"][:\"#{resource_path}\"]")
    branch.add("manipulate", {"id"=>"create_properties_for_#{call_node.attributes['id']}_service_#{index}", "generated"=>"true"}, prop_code)  #}}}
    doc = wf.find("//flow:#{op}/flow:execute", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).first.to_doc
    # The new doc seem's to have lost all namespace-information during document creation
    ns = doc.root.namespaces.add("flow","http://rescue.org/ns/controlflow/0.2")
    doc.find("//*").each { |node| node.namespace = ns }
    branch.add("manipulate", {"id"=>"create_objects_for_#{call_node.attributes['id']}_service_#{index}", "generated"=>"true"}, man_text)
    branch.add("manipulate", {"id"=>"delete_objects_of_#{call_node.attributes['id']}_service_#{index}", "generated"=>"true"}, man_text_delete)
    XML::Smart.string(doc.transform_with(XML::Smart.open("rng+xsl/rescue2cpee.xsl"))).root 
  end# }}}

  def add_service(parallel_node, rescue_client, call_node, cpee_client, resource_path, parent_injected)  # {{{
    status, resp = rescue_client.resource(resource_path).get
    return if status != 200
    if resp[0].name == "atom-feed"
      feed = XML::Smart.string(resp[0].value.read)
      feed.find("//a:entry/a:link", {"a"=>"http://www.w3.org/2005/Atom"}).each do |link|
        add_service(parallel_node, rescue_client, call_node, cpee_client, "#{resource_path}/#{link.text}", parent_injected)
      end
    else
      wf = XML::Smart.string(resp[0].value.read)
      if check_constraints(wf, call_node, cpee_client)
        branch = parallel_node.add("parallel_branch", {"generated"=>"true"})
        branch.add(inject_service_level(wf, call_node, "#{rescue_client.instance_variable_get("@base")}/#{resource_path}", branch, parent_injected).children)
        del_block = branch.find("child::cpee:manipulate[@id='delete_objects_of_#{call_node.attributes['id']}_service_#{"#{rescue_client.instance_variable_get("@base")}/#{resource_path}".gsub("/","_").gsub(":","_")}']", {"cpee"=>"http://cpee.org/ns/description/1.0"}).first
        branch.add(del_block) # Move del-block to last psoition in branch
      end
    end 
  end# }}}  
  
  def check_constraints(wf, call_node, cpee_client)    # {{{
      call_node.find("ancestor::cpee:injected/cpee:constraints", {"cpee" => "http://cpee.org/ns/description/1.0"}).each do |cons|
        bool = true
        cons.children.each do |child|
          bool = check_group(child, cpee_client, wf) if child.name.name == "group"
          bool = check_constraint(child, cpee_client, wf) if child.name.name == "constraint"
          return false if bool == false
        end
      end
      true
  end  # }}}

  def check_group(group, cpee_client, wf)# {{{
    bool = true
    connector = group.attributes['connector']
    group.children.each do |child|
      bool = check_constraint(child, cpee_client, wf) if child.name.name == "constraint"
      bool = check_group(child, cpee_client) if child.name.name == "group"
      return false if connector == "and" and bool == false
      return true if connector =="or" and bool == true
    end
    bool
  end# }}}

  def is_a_number?(s) #{{{
    s.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil ? false : true 
  end#}}}

  def check_constraint(con, cpee_client, wf) #{{{
    xpath = ""
    value1 = con.attributes.include?('value') ? con.attributes['value'] : ""
    if con.attributes.include?('variable')
      status, resp = cpee_client.resource("properties/values/context-variables/#{con.attributes['variable']}").get
      if status != 200
        puts "Could not find variable named #{con.attributes['variable']}"
        return false
      end
      value1 = XML::Smart.string(resp[0].value.read)
      value1 = value1.find("p:value",{"p"=>"http://riddl.org/ns/common-patterns/properties/1.0"}).first.text   #TODO: maybe it would be better to YAML the vaule of the XML?
    end
    con.attributes['xpath'].split('/').each {|p| xpath << "p:#{p}/"}
    xpath.chop! # remove trailing '/'
    value1 = value1.to_f if is_a_number?(value1.strip)
    value2 =  wf.find("//p:properties/#{xpath}", {"p"=>"http://rescue.org/ns/properties/0.2"}).first.text
    value2 = value2.to_f if is_a_number?(value2.strip)
    value2.send(con.attributes['comparator'], value1)
  end#}}}

  def fill_properties(node, index) #{{{
    code = ""
    node.find("child::*").each do |e|
      if e.text.strip == ""
        code << "#{index}[:\"#{e.name.name}\"] = RescueHash.new\n"
        code << fill_properties(e, "#{index}[:\"#{e.name.name}\"]")
      else
        code << "#{index}[:\"#{e.name.name}\"] = \"#{e.text}\"\n"
      end
    end
    code
  end #}}}
end
