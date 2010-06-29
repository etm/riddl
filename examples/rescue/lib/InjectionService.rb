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
      status, resp = cpee_client.resource("/properties/values/description").get # Get description {{{
      unless status == 200
        puts "Error receiving description at #{cpee_uri}/properties/values/description: #{status}"
        return
      end
      description = XML::Smart.string(resp[0].value.read)
      description.namespaces['cpee'] = 'http://cpee.org/ns/description/1.0'  # }}}
      call_node = description.find("//cpee:call[@id = '#{position}']").first # Get call-node, rescue_client and service_operation {{{
      service_operation = call_node.find("descendant::cpee:serviceoperation").first.text.gsub('"','')
      status, resp = cpee_client.resource("properties/values/endpoints/#{call_node.attributes['endpoint']}").get 
      puts "ERROR receiving endpoint named #{call_node.attributes['endpoint']}" unless status == 200
      rescue_uri = XML::Smart.string(resp.value('value').read).root.text
      rescue_client = Riddl::Client.new(rescue_uri)  # }}} 
      injected = description.root.add("injected") # Create injected-block {{{
      injected.attributes['source'] = call_node.attributes['id'] 
      injected.attributes['serviceoperation'] = call_node.find('descendant::cpee:serviceoperation').first.text  # }}}
      parent_injected = call_node.find('ancestor::cpee:injected').last
      class_level = parent_injected.nil? || parent_injected.attributes['serviceoperation'] != injected.attributes['serviceoperation'] # Check if it is an class-level or instance-level injection
      first_ancestor_loop = call_node.find("ancestor::cpee:loop").first # Check if injections is within a loop
# puts first_ancestor_loop.dump
# puts call_node.find("ancestor::cpee:loop").last.dump
      if (class_level) # Injecting class-level {{{
        status, resp = rescue_client.resource("operations/#{service_operation}").get [] # {{{
        unless status == 200
          puts "Error receiving description at #{rescue_uri}/operations/#{service_operation}: #{status}"
          return
        end # }}}
        wf = XML::Smart.string(resp[0].value.read)
        wf.namespaces['flow'] = 'http://rescue.org/ns/controlflow/0.2'
        wf.namespaces['p'] =  'http://rescue.org/ns/properties/0.2'
        sub_controlflow = inject_class_level(wf, call_node, injected).children
        create, remove = maintain_class_level(call_node,wf, injected)
        if first_ancestor_loop.nil?
          injected.add(call_node.find("child::cpee:constraints"), XML::Smart::Dom::Element::COPY)
          injected.add(sub_controlflow)
          man_block = call_node.find("child::cpee:manipulate").first
          call_node.add_after(remove)
          if man_block # Move manipulate into seperate node, set result-attribute for injected and create output context-variable {{{
            man_block.attributes['id'] = "manipulate_from_#{call_node.attributes['id']}"
            man_block.attributes['context'] = "context.result_#{call_node.attributes['id']}"
            injected.attributes['result'] = "context.result_#{call_node.attributes['id']}"
            man_block.attributes['properties'] = "#{injected.attributes['properties']}"
            call_node.add_after(man_block)
          end  # }}} 
          injected.children[1].add_before(create)
          call_node.add_after(injected)
        else
          puts "== Loop-Class-Injection =="*5
# Copy loop-block to new block
# Find new call-block
# Performe injection
# Change ID's
# Check if an other position is within the block
# Add block before ancestor_loop
          puts "== Loop-Class-Injection =="*5
        end
      # }}}
      else   # Injection service-level {{{ 
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
      end # }}}
      new_position = call_node.attributes['id']
      new_state = 'after'
      # Set description {{{
      status, resp = cpee_client.resource("/properties/values/description").put [Riddl::Parameter::Simple.new("content", "<content>#{description.root.dump}</content>")]
      puts "ERROR setting description - status: #{status}" unless status == 200
      # }}} 
      [new_position, new_state]
    rescue => e
      puts $!
      puts e.backtrace
    end
  end# }}}

  def maintain_class_level (call_node, wf, injected) # {{{
    blanks = call_node.find('count(ancestor::cpee:*)').to_i
    blanks_create = ' '*(blanks+1)*2
    blanks_remove = ' '*(blanks)*2
    create = ''
    remove = ''
    parent_injected = call_node.find("ancestor::cpee:injected").last # Create/Remove Property-Objects {{{
    if parent_injected.nil?
      injected.attributes['properties'] = "context.properties_#{call_node.attributes['id']}"
      create << "#{blanks_create}#{injected.attributes['properties']} = RescueHash.new\n"
      remove << "#{blanks_remove}context.delete(:\"properties_#{call_node.attributes['id']}\")\n"
    else
      injected.attributes['properties'] = "#{parent_injected.attributes['properties']}[:\"#{call_node.attributes['oid']}\"]"
    end
    wf.find("//flow:execute/descendant::flow:call[@service-operation]").each do |call|
      c = "#{injected.attributes['properties']}[:\"#{call.attributes.include?('oid') ? call.attributes['oid'] : call.attributes['id'] }\"]"
      create << "#{blanks_create}#{c} = RescueHash.new\n"
    end  #}}} 
    create << "#{blanks_create}context.result_#{call_node.attributes['id']} = RescueHash.new\n" # Create/Remove result-object {{{
    remove << "#{blanks_remove}context.delete(:\"result_#{call_node.attributes['id']}\")\n" # }}}
    wf.find("//flow:endpoints/*").each do |node| # Create/Remove endpoints  {{{
      create << "#{blanks_create}endpoints.#{call_node.attributes['id']+'__'+node.name.name} = #{node.text.inspect}\n"
      remove << "#{blanks_remove}endpoints.delete(:\"#{call_node.attributes['id']+'__'+node.name.name}\")\n"
    end # }}} 
    wf.find("//flow:context-variables/*").each do |node|  # Create/Remoce context-variables {{{
      create << "#{blanks_create}context.#{call_node.attributes['id']+'__'+node.name.name} = "
      create << (node.attributes.include?('class') ? node.attributes['class'] : "#{node.text.inspect}") + "\n"
      remove << "#{blanks_remove}context.delete(:\"#{call_node.attributes['id']+'__'+node.name.name}\")\n"
    end # }}}
    create  = injected.add("manipulate", {"id"=>"create_objects_for_#{call_node.attributes['id']}", "generated"=>"true"}, create)
    remove = injected.add("manipulate", {"id"=>"remove_objects_of_#{call_node.attributes['id']}", "generated"=>"true"}, remove)
    [create, remove]
  end # }}}

  def inject_class_level(wf, call_node, injected) # {{{
    # Change attributes {{{
    wf.find("//@id").each do |a| 
      a.element.attributes['oid'] = a.value 
      a.value = call_node.attributes['id']+'__'+a.value
    end
    wf.find("//flow:call").each do |a|
      if a.attributes.include?('endpoint-type') and a.attributes['endpoint-type'] == "outside"
        ep = call_node.find("child::cpee:parameters/cpee:additional_endpoints/cpee:#{a.attributes['endpoint']}").first.text
        a.attributes['endpoint'] = ep.gsub('"', "")
      else
        a.attributes['endpoint'] = a.attributes['endpoint'] == "resource_path" ? call_node.attributes['endpoint'] : call_node.attributes['id']+'__'+a.attributes['endpoint']
      end
    end
    wf.find("//flow:call/@wsdl").each do |a|
      a.value = call_node.attributes['id']+'__'+a.value
    end
    wf.find("//flow:call/flow:resource-id").each do |a|
      if a.attributes.include?('endpoint-type') and a.attributes['endpoint-type'] == "outside"
        ep = call_node.find("child::cpee:parameters/cpee:additional_endpoints/cpee:#{a.attributes['endpoint']}").first.text
        a.attributes['endpoint'] = ep.gsub('"', "")
      else
        a.attributes['endpoint'] = a.attributes['endpoint'] == "resource_path" ? call_node.attributes['endpoint'] : call_node.attributes['id']+'__'+a.attributes['endpoint']
      end
    end
    wf.find("//@variable").each {|a| a.value = "context.#{call_node.attributes['id']}__#{a.value}"} 
    wf.find("//@test").each {|a| a.value = "context.#{call_node.attributes['id']}__#{a.value}"}
    wf.find("//@context").each {|a| a.value = "context.#{call_node.attributes['id']}__#{a.value}"}
    wf.find("//@input-parameter").each do |a| 
      p = call_node.find("child::cpee:parameters/cpee:parameters/cpee:#{a.value}").first
      a.value = p.text if p
      puts "Variable for manipulate-block #{a.parent.parent.attributes['id']} named #{a.value} not found" unless p
    end
    wf.find("//@output-parameter").each do |a|
      a.value = "context.result_#{call_node.attributes['id']}[:#{a.value}]"
    end # }}} 
    # Resovle message-parameter {{{
    wf.find("//flow:execute/descendant::flow:input[string(@message-parameter)]").delete_if! do |p|
      var =  call_node.find("child::cpee:parameters/cpee:parameters/cpee:#{p.attributes['message-parameter']}").first
      temp = p.parent.add("input", {"name"=>p.attributes['name'], "variable"=>var.text}) if var
      puts "Variable named #{p.attributes['message-parameter']} could not be resolved" unless var
      true
    end
    wf.find("//flow:execute/descendant::flow:output[string(@message-parameter)]").each do |output|
      call = output.parent
      res_object = call_node.find("ancestor::cpee:injected[string(@result)]").last
      str = res_object.nil? ? "context.result_#{call_node.attributes['id']}" : "#{res_object.attributes['result']}"
      output.attributes['message-parameter'] = "#{str}[:#{output.attributes['message-parameter']}]"
    end # }}}
    # Add repositroy-information to new operation-calls {{{
    wf.find("//flow:execute/descendant::flow:call").each do |call|
      call.attributes['injection_handler'] = call_node.find("string(child::cpee:parameters/cpee:service/cpee:injection_handler)").first
    end # }}}
    doc = wf.find("//flow:execute").first.to_doc
    XML::Smart.string(doc.transform_with(XML::Smart.open("rng+xsl/rescue2cpee.xsl"))).root 
  end# }}}

  def maintain_instance_level(wf, call_node, parent_injected, resource_path) # {{{
    blanks = call_node.find('count(ancestor::cpee:*)').to_i
    blanks = ' '*(blanks+3)*2
    op = parent_injected.attributes['serviceoperation'].tr('"', '')
    index = resource_path.tr('/:','__')
    create = "#{blanks}#{parent_injected.attributes['result']}[:\"#{resource_path}\"] = RescueHash.new\n"
    remove = ''
    wf.find("//flow:#{op}/flow:endpoints/*").each do |node| # Create/Remove endpints {{{
      create << "#{blanks}endpoints.#{call_node.attributes['id']+'__'+index+'__'+node.name.name} = #{node.text.inspect}\n"
      remove << "#{blanks}endpoints.delete(:\"#{ call_node.attributes['id']+'__'+index+'__'+node.name.name}\")\n"
    end # }}}
    # Create/Remove context-variables {{{ 
    wf.find("//flow:#{op}/flow:context-variables/*").each do |node|
      create << "#{blanks}context.#{call_node.attributes['id']+'__'+index+'__'+node.name.name} = "
      create << (node.attributes.include?('class') ? node.attributes['class'] : "#{node.text.inspect}") + "\n"
      remove << "#{blanks}context.delete(:\"#{call_node.attributes['id']+'__'+index+'__'+node.name.name}\")\n"
    end # }}}
    create << "#{blanks}# Filling the properties-object og the service\n"
    create << "#{blanks}#{parent_injected.attributes['propertiers']}[:\"#{call_node.attributes['oid']}\"][:\"#{resource_path}\"] = RescueHash.new\n"
    create << fill_properties(wf.find("//p:properties").first, "#{parent_injected.attributes['properties']}[:\"#{call_node.attributes['oid']}\"][:\"#{resource_path}\"]", blanks)
    create = call_node.add("manipulate", {"id"=>"create_objects_for_#{call_node.attributes['id']}_service_#{index}", "generated"=>"true"}, create)
    remove = call_node.add("manipulate", {"id"=>"delete_objects_of_#{call_node.attributes['id']}_service_#{index}", "generated"=>"true"}, remove)
    [create, remove]
  end # }}}

  def fill_properties(node, index, blanks) #{{{
    code = ""
    node.find("child::*").each do |e|
      if e.text.strip == ""
        code << "#{blanks}#{index}[:\"#{e.name.name}\"] = RescueHash.new\n"
        code << fill_properties(e, "#{index}[:\"#{e.name.name}\"]", blanks)
      else
        code << "#{blanks}#{index}[:\"#{e.name.name}\"] = \"#{e.text}\"\n"
      end
    end
    code
  end #}}}

  def inject_instance_level(wf, call_node, resource_path, branch, parent_injected)# {{{
    index = resource_path.tr('/:','__')
    op = parent_injected.attributes['serviceoperation'].tr('"', '')
    # Change id's {{{ 
    wf.find("//@id").each {|a| a.value = call_node.attributes['id']+'__'+index+'__'+a.value} # }}}   
    # Change endpoints  {{{
    wf.find("//@endpoint").each do |a|
      a.value = call_node.attributes['id']+'__'+index+'__'+a.value
    end # }}} 
    wf.find("//flow:call/@wsdl").each do |a|
      a.value = call_node.attributes['id']+'__'+index+'__'+a.value
    end
    wf.find("//flow:#{op}/descendant::flow:*/@variable").each {|a| a.value = "context.#{call_node.attributes['id']}__#{index}__#{a.value}"}
    wf.find("//flow:#{op}/descendant::flow:*/@test").each {|a| a.value = "context.#{call_node.attributes['id']}__#{index}__#{a.value}"}
    wf.find("//flow:#{op}/descendant::flow:*/@context").each {|a| a.value = "context.#{call_node.attributes['id']}__#{index}__#{a.value}"}
    wf.find("//flow:#{op}/descendant::flow:*/@input-parameter").each do |a| 
      p = call_node.find("child::cpee:parameters/cpee:parameters/cpee:#{a.value}").first
      a.value = p.text if not p.nil?
      puts "Variable for manipulate-block #{a.element.parent.attributes['id']} named #{a.value} not found" if p.nil?
    end
    wf.find("//flow:#{op}/descendant::flow:*/@output-parameter").each do |a|
      res_object = call_node.find("ancestor::cpee:injected[string(@result)]").last
      a.value = "#{parent_injected.attributes['result']}[:\"#{resource_path}\"][:#{a.value}]" unless res_object.nil?
    end # }}}
    # Resovle message-parameter {{{
    wf.find("//flow:#{op}/descendant::flow:input[string(@message-parameter)]").delete_if! do |p|
      var =  call_node.find("child::cpee:parameters/cpee:parameters/cpee:#{p.attributes['message-parameter']}").first
      temp = p.parent.add("input", {"name"=>p.attributes['name'], "variable"=>var.text}) if var
      puts "Variable named #{p.attributes['message-parameter']} could not be resolved" if not var
      true
    end
    wf.find("//flow:#{op}/descendant::flow:output[string(@message-parameter)]").each do |p|
      res_object = call_node.find("ancestor::cpee:injected[string(@result)]").last
      p.attributes['message-parameter'] = "#{parent_injected.attributes['result']}[:\"#{resource_path}\"][:#{p.attributes['message-parameter']}]" if not res_object.nil?
    end # }}}
    doc = wf.find("//flow:#{op}/flow:execute").first.to_doc
    # The new doc seem's to have lost all namespace-information during document creation
    ns = doc.root.namespaces.add("flow","http://rescue.org/ns/controlflow/0.2")
    doc.find("//*").each { |node| node.namespace = ns }
    create, remove = maintain_instance_level(wf, call_node, parent_injected, resource_path)
    branch.add(create)
    branch.add(remove)
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
      wf.namespaces['flow'] = 'http://rescue.org/ns/controlflow/0.2'
      wf.namespaces['p'] = 'http://rescue.org/ns/properties/0.2'
      if check_constraints(wf, call_node, cpee_client)
        branch = parallel_node.add("parallel_branch", {"generated"=>"true"})
        branch.add(inject_instance_level(wf, call_node, "#{rescue_client.instance_variable_get("@base")}/#{resource_path}", branch, parent_injected).children)
        del_block = branch.find("child::cpee:manipulate[@id='delete_objects_of_#{call_node.attributes['id']}_service_#{"#{rescue_client.instance_variable_get("@base")}/#{resource_path}".tr('/:','_')}']").first
        branch.add(del_block) # Move del-block to last psoition in branch
      end
    end 
  end# }}}  
  
  def check_constraints(wf, call_node, cpee_client)    # {{{
      call_node.find("ancestor::cpee:injected/cpee:constraints").each do |cons|
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
    value2 =  wf.find("//p:properties/#{xpath}").first.text
    value2 = value2.to_f if is_a_number?(value2.strip)
    value2.send(con.attributes['comparator'], value1)
  end#}}}

end
