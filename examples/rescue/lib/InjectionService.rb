require '../../lib/ruby/client'

class InjectionService < Riddl::Implementation
  def response  #{{{
    puts "== Injection-service: injecting position #{@p.value('position')} on instance #{@p.value('instance')}"
    positions =  analyze(@p.value('position'), @p.value('instance'), @p.value('handler'))
    pos = XML::Smart.string('<positions/>') # Set positions {{{
    positions.each { |p| pos.root.add(p[:old].to_s, {'new'=>p[:new].to_s}, p[:state].to_s) }
    Riddl::Parameter::Complex.new('positions', 'text/xml', pos.root.dump) # }}}
  end# }}}  

  def analyze(position, instance, handler_uri)# {{{ 
    begin
      injected = nil
      positions = Array.new
      cpee_client = Riddl::Client.new(instance)
      status, resp = cpee_client.resource("/properties/values/description").get # Get description {{{
      unless status == 200
        puts "Error receiving description at #{cpee_uri}/properties/values/description: #{status}"
        return
      end
      description = XML::Smart.string(resp[0].value.read)
      description.namespaces['cpee'] = 'http://cpee.org/ns/description/1.0'  # }}}
      call_node = description.find("//cpee:call[@id = '#{position}']").first # Get call-node, rescue_client and service_operation {{{
      service_operation = call_node.find("descendant::cpee:serviceoperation").first.text.tr('"','')
      status, resp = cpee_client.resource("properties/values/endpoints/#{call_node.attributes['endpoint']}").get 
      puts "ERROR receiving endpoint named #{call_node.attributes['endpoint']}" unless status == 200
      rescue_uri = XML::Smart.string(resp.value('value').read).root.text
      rescue_client = Riddl::Client.new(rescue_uri)  # }}} 
      parent_injected = call_node.find("ancestor::cpee:injected[@type='injection']").last
      class_level = parent_injected.nil? || parent_injected.attributes['serviceoperation'] != call_node.find('descendant::cpee:serviceoperation').first.text # Check if it is an class-level or instance-level injection
      first_ancestor_loop = call_node.find("ancestor::cpee:loop").first # Check if injections is within a loop
      if (class_level) # Injecting class-level {{{
        status, resp = rescue_client.resource("operations/#{service_operation}").get [] # {{{
        unless status == 200
          puts "Error receiving description at #{rescue_uri}/operations/#{service_operation}: #{status}"
          return
        end # }}}
        wf = XML::Smart.string(resp[0].value.read)
        wf.namespaces['flow'] = 'http://rescue.org/ns/controlflow/0.2'
        wf.namespaces['p'] =  'http://rescue.org/ns/properties/0.2'
        if first_ancestor_loop.nil?
          inject_class_level(wf, call_node)
          positions << {:old=>call_node.attributes['id'], :new=>call_node.attributes['id'], :state=>'after'}
        else
          puts "== Loop-Class-Injection =="*5
          first_ancestor_loop.find('./@post_test').delete_if! {first_ancestor_loop.attributes['pre_test'] = first_ancestor_loop.attributes['post_test']; true}
          # Copy loop-block to new block {{{
          preceding_loops = call_node.find("count(ancestor::cpee:loop[1]/preceding-sibling::cpee:injected[@type='loop' and @source='#{call_node.attributes['id']}'])").to_i
          loop_copy = call_node.find('/*').first.add('injected', {'type' => 'loop', 'source' => call_node.attributes['id'], 'cycle' => preceding_loops})
          loop_copy.add(first_ancestor_loop.children, XML::Smart::Dom::Element::COPY) # }}}
          # Set new position and check if other positions are within the block {{{
          positions << {:old=>call_node.attributes['id'], :new=>"#{call_node.attributes['id']}_#{preceding_loops}", :state=>'after'}
          handler = Riddl::Client.new(handler_uri)
          status, resp = handler.get [Riddl::Parameter::Simple.new('instance', instance)]
          puts "ERROR: Receiving queue status: #{status}" unless status == 200
          queue = XML::Smart.string(resp[0].value.read)
          queue.find('/injection-queue/cpee-positions/*').each do |cpee_pos|
             p = loop_copy.find("descendant::cpee:*[@id='#{cpee_pos.name.name}']").first
             positions << {:old=>cpee_pos.name.name, :new=>"#{cpee_pos.name.name}_#{preceding_loops}", :state=>'after'} unless p.nil? || cpee_pos.name.name == call_node.attributes['id']
          end
          # }}}
          call_node = loop_copy.find("descendant::cpee:call[@id = '#{call_node.attributes['id']}']").first # Find new call-block
          inject_class_level(wf, call_node) # Performe injection
          loop_copy.find('descendant::cpee:*[@id]').each {|node| node.attributes['id'] =  "#{node.attributes['id']}_#{preceding_loops}"} # Change ID's
          # Add block before ancestor_loop
          first_ancestor_loop.add_before(loop_copy)
          puts "== Loop-Class-Injection =="*5
        end
      # }}}
      else   # Injection instance-level {{{ 
        injected = description.root.add("injected") # Create injected-block {{{
        injected.attributes['source'] = call_node.attributes['id'] 
        injected.attributes['type'] = 'injection' 
        injected.attributes['serviceoperation'] = call_node.find('descendant::cpee:serviceoperation').first.text  # }}}
        parallel = injected.add("parallel", {"generated"=>"true"})
        prop = call_node.find("ancestor::cpee:injected[@type='injection']", {"cpee" => "http://cpee.org/ns/description/1.0"}).last.attributes['properties']
        injected.attributes['properties'] = "#{prop}[:\"#{call_node.attributes['oid']}\"]"
        if first_ancestor_loop.nil?
          add_service(parallel, rescue_client, call_node, cpee_client, "", parent_injected)
          call_node.add_after(injected)
          positions << {:old=>call_node.attributes['id'], :new=>call_node.attributes['id'], :state=>'after'}
        else
          puts "== Loop-Instance-Injection =="*5
          first_ancestor_loop.find('./@post_test').delete_if! {first_ancestor_loop.attributes['pre_test'] = first_ancestor_loop.attributes['post_test']; true}
          # Copy loop-block to new block
          preceding_loops = call_node.find("count(ancestor::cpee:loop[1]/preceding-sibling::cpee:injected[@type='loop' and @source='#{call_node.attributes['id']}'])").to_i
          loop_copy =  call_node.find('/*').first.add('injected', {'type' => 'loop', 'source' => call_node.attributes['id'], 'cycle' => preceding_loops})
          loop_copy.add(first_ancestor_loop.children, XML::Smart::Dom::Element::COPY)
          # Set new position and check if other positions are within the block {{{
          positions << {:old=>call_node.attributes['id'], :new=>"#{call_node.attributes['id']}_#{preceding_loops}", :state=>'after'}
          handler = Riddl::Client.new(handler_uri)
          status, resp = handler.get [Riddl::Parameter::Simple.new('instance', instance)]
          puts "ERROR: Receiving queue status: #{status}" unless status == 200
          queue = XML::Smart.string(resp[0].value.read)
          queue.find('/injection-queue/cpee-positions/*').each do |cpee_pos|
             p = loop_copy.find("descendant::cpee:*[@id='#{cpee_pos.name.name}']").first
             positions << {:old=>cpee_pos.name.name, :new=>"#{cpee_pos.name.name}_#{preceding_loops}", :state=>'after'} unless p.nil? || cpee_pos.name.name == call_node.attributes['id']
          end
          # }}}
          # Find new call-block
          call_node = loop_copy.find("descendant::cpee:call[@id = '#{call_node.attributes['id']}']").first
          # Move manipulate into seperate node, set result-attribute for injected and create output context-variable {{{
          man_block = call_node.find("child::cpee:manipulate").first
          if man_block
            man_block.attributes['id'] = "manipulate_from_#{call_node.attributes['id']}"
            man_block.attributes['context'] = parent_injected.attributes['result']
            man_block.attributes['properties'] = "#{parent_injected.attributes['properties']}"
            call_node.add_after(man_block)
          end  # }}} 
          # Performe injection
          add_service(parallel, rescue_client, call_node, cpee_client, "", parent_injected)
          call_node.add_after(injected)
          # Change ID's
          loop_copy.find('descendant::cpee:*[@id]').each {|node| node.attributes['id'] =  "#{node.attributes['id']}_#{preceding_loops}"}
          # Check if an other position is within the block
          # TODO
          # Add block before ancestor_loop
          first_ancestor_loop.add_before(loop_copy)
          puts "== Loop-Instance-Injection =="*5
        end
      end # }}}
      # Set description {{{
      status, resp = cpee_client.resource("/properties/values/description").put [Riddl::Parameter::Simple.new("content", "<content>#{description.root.dump}</content>")]
      puts "ERROR setting description - status: #{status}" unless status == 200
      # }}} 
      positions
    rescue => e
      puts $!
      puts e.backtrace
    end
  end# }}}

  def maintain_class_level (call_node, wf, injected)  # {{{
    blanks = call_node.find('count(ancestor::cpee:*)').to_i
    blanks_create = ' '*(blanks+1)*2
    blanks_remove = ' '*(blanks)*2
    create = ''
    remove = ''
    parent_injected = call_node.find("ancestor::cpee:injected[@type='injection']").last # Create/Remove Property-Objects {{{
    if parent_injected.nil?
      create << "#{blanks_create}#{injected.attributes['properties']} = RescueHash.new\n"
      remove << "#{blanks_remove}context.delete(:\"properties_#{call_node.attributes['id']}\")\n"
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
      create << (node.attributes.include?('class') ? node.attributes['class'] : "#{node.text.empty? ? "''" : node.text}") + "\n"
      remove << "#{blanks_remove}context.delete(:\"#{call_node.attributes['id']+'__'+node.name.name}\")\n"
    end # }}}
    create  = injected.add("manipulate", {"id"=>"create_objects_for_#{call_node.attributes['id']}", "generated"=>"true"}, create)
    remove = injected.add("manipulate", {"id"=>"remove_objects_of_#{call_node.attributes['id']}", "generated"=>"true"}, remove)
    [create, remove]
  end # }}}

  def inject_class_level(wf, call_node) # {{{
    injected = call_node.add("injected") # Create injected-block {{{
    injected.attributes['type'] = 'injection'
    injected.attributes['source'] = call_node.attributes['id'] 
    injected.attributes['serviceoperation'] = call_node.find('descendant::cpee:serviceoperation').first.text 
    injected.attributes['result'] = "context.result_#{call_node.attributes['id']}"
    parent_injected = call_node.find("ancestor::cpee:injected[@type='injection']").last
    if parent_injected.nil?
      injected.attributes['properties'] = "context.properties_#{call_node.attributes['id']}" 
    else
      injected.attributes['properties'] = "#{parent_injected.attributes['properties']}[:\"#{call_node.attributes['oid']}\"]"
    end
    injected.add(call_node.find("child::cpee:constraints"), XML::Smart::Dom::Element::COPY) #}}}
    create, remove = maintain_class_level(call_node, wf, injected)
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
      p.parent.add("input", {"name"=>p.attributes['name'], "variable"=>var.text}) if var
      puts "Variable named #{p.attributes['message-parameter']} could not be resolved" unless var
      true
    end
    wf.find("//flow:execute/descendant::flow:output[string(@message-parameter)]").each do |output|
      call = output.parent
      res_object = call_node.find("ancestor::cpee:injected[string(@result) and (@type='injection')]").last
      str = res_object.nil? ? "context.result_#{call_node.attributes['id']}" : "#{res_object.attributes['result']}"
      output.attributes['message-parameter'] = "#{str}[:#{output.attributes['message-parameter']}]"
    end # }}}
    # Add repositroy-information to new operation-calls {{{
    wf.find("//flow:execute/descendant::flow:call").each do |call|
      call.attributes['injection_handler'] = call_node.find("string(child::cpee:parameters/cpee:service/cpee:injection_handler)").first
    end # }}}
    # Move manipulate into seperate node, set result-attribute for injected and create output context-variable {{{
    man_block = call_node.find("child::cpee:manipulate").first
    if man_block
      man_block.attributes['id'] = "manipulate_from_#{call_node.attributes['id']}"
      man_block.attributes['context'] = "context.result_#{call_node.attributes['id']}"
      man_block.attributes['properties'] = "#{injected.attributes['properties']}"
      call_node.add_after(man_block)
    end  # }}} 
    injected.add(create)
    doc = wf.find("//flow:execute").first.to_doc
    injected.add(XML::Smart.string(doc.transform_with(XML::Smart.open("rng+xsl/rescue2cpee.xsl"))).root.children)
    call_node.add_after(injected)
    man_block.nil? ? injected.add_after(remove) : man_block.add_after(remove)
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
      create << (node.attributes.include?('class') ? node.attributes['class'] : "#{node.text.empty? ? "''" : node.text}") + "\n"
      remove << "#{blanks}context.delete(:\"#{call_node.attributes['id']+'__'+index+'__'+node.name.name}\")\n"
    end # }}}
    create << "#{blanks}# Filling the properties-object og the service\n"
    create << "#{blanks}#{parent_injected.attributes['properties']}[:\"#{call_node.attributes['oid']}\"][:\"#{resource_path}\"] = RescueHash.new\n"
    create << fill_properties(wf.find("//p:properties").first, "#{parent_injected.attributes['properties']}[:\"#{call_node.attributes['oid']}\"][:\"#{resource_path}\"]", blanks)
    create = call_node.add("manipulate", {"id"=>"create_objects_for_#{call_node.attributes['id']}_service_#{index}", "generated"=>"true"}, create)
    remove = call_node.add("manipulate", {"id"=>"remove_objects_of_#{call_node.attributes['id']}_service_#{index}", "generated"=>"true"}, remove)
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
    wf.find("//@id").each {|a| a.value = call_node.attributes['id']+'__'+index+'__'+a.value}
    wf.find("//@endpoint").each {|a| a.value = call_node.attributes['id']+'__'+index+'__'+a.value }
    wf.find("//flow:call/@wsdl").each {|a| a.value = call_node.attributes['id']+'__'+index+'__'+a.value }
    wf.find("//flow:#{op}/descendant::flow:*/@variable").each {|a| a.value = "context.#{call_node.attributes['id']}__#{index}__#{a.value}"}
    wf.find("//flow:#{op}/descendant::flow:*/@test").each {|a| a.value = "context.#{call_node.attributes['id']}__#{index}__#{a.value}"}
    wf.find("//flow:#{op}/descendant::flow:*/@context").each {|a| a.value = "context.#{call_node.attributes['id']}__#{index}__#{a.value}"}
    wf.find("//flow:#{op}/descendant::flow:*/@input-parameter").each do |a| 
      p = call_node.find("child::cpee:parameters/cpee:parameters/cpee:#{a.value}").first
      a.value = p.nil? ? "\"not found\"" : p.text 
    end
    wf.find("//flow:#{op}/descendant::flow:*/@output-parameter").each { |a| a.value = "#{parent_injected.attributes['result']}[:\"#{resource_path}\"][:#{a.value}]" }
    # Resovle message-parameter {{{
    wf.find("//flow:#{op}/descendant::flow:input[string(@message-parameter)]").delete_if! do |p|
      var = call_node.find("child::cpee:parameters/cpee:parameters/cpee:#{p.attributes['message-parameter']}").first
      p.parent.add("input", {"name"=>p.attributes['name'], "variable"=>var.text}) if var 
      true
    end
    wf.find("//flow:#{op}/descendant::flow:output[string(@message-parameter)]").each do |p|
      p.attributes['message-parameter'] = "#{parent_injected.attributes['result']}[:\"#{resource_path}\"][:#{p.attributes['message-parameter']}]" if  parent_injected.attributes['result']
    end # }}}
    doc = wf.find("//flow:#{op}/flow:execute").first.to_doc
    # The new doc seem's to have lost all namespace-information during document creation
    ns = doc.root.namespaces.add("flow","http://rescue.org/ns/controlflow/0.2")
    doc.find("//*").each { |node| node.namespace = ns }
    create, remove = maintain_instance_level(wf, call_node, parent_injected, resource_path)
    branch.add(create)
    branch.add(XML::Smart.string(doc.transform_with(XML::Smart.open("rng+xsl/rescue2cpee.xsl"))).root.children) 
    branch.add(remove)
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
        inject_instance_level(wf, call_node, "#{rescue_client.instance_variable_get("@base")}/#{resource_path}", branch, parent_injected)
      end
    end 
  end# }}}  
  
  def check_constraints(wf, call_node, cpee_client)    # {{{
      call_node.find("ancestor::cpee:injected[@type='injection']/cpee:constraints").each do |cons|
        bool = true
        cons.children.each do |child|
          bool = check_group(child, cpee_client, wf) if child.name.name == "group"
          bool = check_constraint(child, cpee_client, wf) if child.name.name == "constraint"
          return false unless bool
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
