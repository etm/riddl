require '../../lib/ruby/client'

class InjectionService < Riddl::Implementation
  def response  #{{{
    description = XML::Smart.string(@p.value('description').read)
    description.namespaces['cpee'] = 'http://cpee.org/ns/description/1.0'
    positions, description =  analyze(@p.value('position'), @p.value('instance'), @p.value('handler'), description)
    pos = XML::Smart.string('<positions/>')
    positions.each { |old, new| pos.root.add(old.to_s, {'new'=>new[:pos].to_s}, new[:state].to_s) }
    [ Riddl::Parameter::Complex.new('positions', 'text/xml', pos.root.dump),  Riddl::Parameter::Complex.new('description', 'text/xml', description.root.dump)]
  end# }}}  

  def analyze(position, instance, handler_uri, description=nil, positions=nil)# {{{ 
    wf = nil; parallel = nil; create = nil; remove = nil; injected = nil; # because of variable scoping
    positions = Hash.new if positions.nil?
    cpee_client = Riddl::Client.new(instance)
    call_node = description.find("//cpee:call[@id = '#{position}']").first # Get call-node, rescue_client and service_operation {{{
    service_operation = call_node.find("string(descendant::cpee:serviceoperation)").tr('"','')
    status, resp = cpee_client.resource("properties/values/endpoints/#{call_node.attributes['endpoint']}").get # Get endpoint {{{
    unless status == 200
      puts "ERROR receiving endpoint named #{call_node.attributes['endpoint']}"
      return []
    end #}}}
    rescue_uri = XML::Smart.string(resp.value('value').read).root.text
    rescue_client = Riddl::Client.new(rescue_uri)  # }}} 
    parent_injected = call_node.find("ancestor::cpee:group[@type='injection']").last
    class_level = parent_injected.nil? || parent_injected.attributes['serviceoperation'] != call_node.find('string(descendant::cpee:serviceoperation)') # Check if it is an class-level or instance-level injection
    first_ancestor_loop = call_node.find("ancestor::cpee:loop").first # Check if injections is within a loop, and not already injected via a loop
    injected = call_node.add("group", {'type'=>'injection', 'source'=>call_node.attributes['id'], 'serviceoperation'=>call_node.find('string(descendant::cpee:serviceoperation)')}) # Create injected-block {{{
    injected.attributes['result'] = "context.result_#{call_node.attributes['id']}" if class_level
    parent_injected = call_node.find("ancestor::cpee:group[@type='injection']").last
    if parent_injected.nil?
      injected.attributes['properties'] = "context.result_#{call_node.attributes['id']}['properties']" 
    else
      injected.attributes['properties'] = "#{parent_injected.attributes['properties']}[\"#{call_node.attributes['oid']}\"]"
    end
    injected.add(call_node.find("child::cpee:constraints"), XML::Smart::Dom::Element::COPY) #}}}
    if class_level # {{{
      status, resp = rescue_client.resource("operations/#{service_operation}").get [] # {{{
      unless status == 200
        puts "Error receiving description at #{rescue_uri}/operations/#{service_operation}: #{status}"
        return []
      end # }}}
      wf = XML::Smart.string(resp[0].value.read)
      wf.namespaces['flow'] = 'http://rescue.org/ns/controlflow/0.2'
      wf.namespaces['p'] =  'http://rescue.org/ns/properties/0.2'
      wf.find('//flow:call[child::flow:templates]').each {|c| c.attributes['templates-uri'] = "#{rescue_uri}/operations/#{service_operation}/templates/#{c.attributes['id']}" }
      if first_ancestor_loop.nil?
        create, remove = inject_class_level(wf, call_node, injected)
        positions[call_node.attributes['id']] = {:pos=>call_node.attributes['id'], :state=>'after'}
      end # }}}
    else # {{{
      parallel = injected.add("parallel", {"generated"=>"true"})
      if first_ancestor_loop.nil?
        add_service(parallel, rescue_client, call_node, cpee_client, "", parent_injected)
        positions[call_node.attributes['id']] = {:pos=>call_node.attributes['id'], :state=>'after'}
      end
    end # }}}
    unless first_ancestor_loop.nil? # {{{ 
      first_ancestor_loop.find('./@post_test').delete_if! {first_ancestor_loop.attributes['pre_test'] = first_ancestor_loop.attributes['post_test']; true}
      # Copy loop-block to new block {{{
      #preceding_loops = call_node.find("count(ancestor::cpee:loop[last()]/preceding-sibling::cpee:group[@type='loop' and @source='#{call_node.attributes['id']}'])").to_i
      preceding_loops = call_node.find("count(ancestor::cpee:loop[last()]/preceding-sibling::cpee:group[@type='loop'])").to_i # Becaus we can not differ between two sequential loops ther would be problems with the counting of the iterations as lon ther is no UID for loops
      loop_copy = call_node.find('/*').first.add('group', {'type' => 'loop', 'source' => call_node.attributes['id'], 'cycle' => preceding_loops})
      loop_copy.add(first_ancestor_loop.children, XML::Smart::Dom::Element::COPY) # }}}
      # Set new position and check if other positions are within the block {{{
      if positions.length < 1 # means that a position object was not given -> in a loop-injection recursion
        status, resp = Riddl::Client.new(handler_uri).get [Riddl::Parameter::Simple.new('instance', instance)]
        unless status == 200
          puts "ERROR: Receiving queue status: #{status}"
          return []
        end
        XML::Smart.string(resp[0].value.read).find('/injection-queue/*[(name() = "cpee-positions") or (name() = "queued")]/*').each do |cpee_pos|
           positions[cpee_pos.name.name] = {:pos=>"#{cpee_pos.name.name}_#{preceding_loops}", :state=>'after'} unless loop_copy.find("descendant::cpee:*[@id='#{cpee_pos.name.name}']").first.nil? 
        end
      else
        positions.each do |old, new|
          positions[old] = {:pos=>"#{new[:pos]}_#{preceding_loops}", :state=>'after'} unless loop_copy.find("descendant::cpee:*[@id='#{new[:pos]}']").first.nil?
        end
      end # }}}
      call_node = loop_copy.find("descendant::cpee:call[@id = '#{call_node.attributes['id']}']").first # Find new call-block
      loop_copy.find('descendant::cpee:*[@id]').each {|node| node.attributes['id'] =  "#{node.attributes['id']}_#{preceding_loops}"} # Change ID's {{{
      injected.attributes['result'] = "context.result_#{call_node.attributes['id']}" if class_level
      injected.attributes['properties'] = "context.result_#{call_node.attributes['id']}['properties']" if parent_injected.nil? # }}}
      unless call_node.find('ancestor::cpee:loop').first.nil?
        first_ancestor_loop.add_before(loop_copy)
        return  analyze(call_node.attributes['id'], instance, handler_uri, description, positions)
      end
      # Performe injection # {{{
      create, remove = inject_class_level(wf, call_node, injected) if class_level 
      add_service(parallel, rescue_client, call_node, cpee_client, "", parent_injected) unless class_level # }}}
      first_ancestor_loop.add_before(loop_copy)  # Add block before ancestor_loop
    end # }}}
    # Move manipulate into seperate node, set result-attribute for injected and create output conext-variable {{{
    man_block = call_node.find("child::cpee:manipulate").first
    if man_block
      man_block.attributes['id'] = "manipulate_from_#{call_node.attributes['id']}"
      man_block.attributes['context'] =  class_level ? "context.result_#{call_node.attributes['id']}" : parent_injected.attributes['result'] 
      p_text = "properties = #{(parent_injected ? "#{parent_injected.attributes['properties']}" : injected.attributes['properties'])}\n"
      man_block.text = p_text + man_block.text
      man_block.attributes['properties'] = parent_injected ? "#{parent_injected.attributes['properties']}" : injected.attributes['properties']
      call_node.add_after(man_block)
    end  # }}} 
    call_node.add_after(injected)
    if class_level
      injected.children[0].add_before(create)
      man_block.nil? ? injected.add_after(remove) : man_block.add_after(remove)
    end
    [positions, description]
  end# }}}

  def maintain_class_level (call_node, wf, injected)  # {{{
    blanks = call_node.find('count(ancestor::cpee:*)').to_i
    blanks_create = ' '*(blanks+1)*2; blanks_remove = ' '*(blanks)*2
    create = ''; remove = ''
    create << "#{blanks_create}context.result_#{call_node.attributes['id']} = RescueHash.new\n" # Create/Remove result-object {{{
    remove << "#{blanks_remove}context.delete(:\"result_#{call_node.attributes['id']}\")\n" # }}}
    parent_injected = call_node.find("ancestor::cpee:group[@type='injection']").last # Create/Remove Property-Objects {{{
    if parent_injected.nil?
      create << "#{blanks_create}#{injected.attributes['properties']} = RescueHash.new\n"
      remove << "#{blanks_remove}context.delete(:\"properties_#{call_node.attributes['id']}\")\n"
    end
    wf.find("//flow:execute/descendant::flow:call[@service-operation]").each do |call|
      c = "#{injected.attributes['properties']}[\"#{call.attributes.include?('oid') ? call.attributes['oid'] : call.attributes['id'] }\"]"
      create << "#{blanks_create}#{c} = RescueHash.new\n"
    end  #}}} 
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
    remove =  injected.add("manipulate", {"id"=>"remove_objects_of_#{call_node.attributes['id']}", "generated"=>"true"}, remove)
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
        ep = call_node.find("string(child::cpee:parameters/cpee:additional_endpoints/cpee:#{a.attributes['endpoint']})")
        a.attributes['endpoint'] = ep.tr('"', "")
      else
        a.attributes['endpoint'] = a.attributes['endpoint'] == "resource_path" ? call_node.attributes['endpoint'] : call_node.attributes['id']+'__'+a.attributes['endpoint']
      end
    end
    wf.find("//flow:call/@wsdl").each do |a|
      a.value = call_node.attributes['id']+'__'+a.value
    end
    wf.find("//@variable").each           {|a| a.value = "context.#{call_node.attributes['id']}__#{a.value}"} 
    wf.find("//@test").each               {|a| a.value = "context.#{call_node.attributes['id']}__#{a.value}"}
    wf.find("//@context").each            {|a| a.value = "context.#{call_node.attributes['id']}__#{a.value}"}
    wf.find("//flow:variable/@endpoint").each  {|a| a.value = "endpoints.#{call_node.attributes['id']}__#{a.value}"}
    wf.find("//@input-parameter").each do |a| 
      p = call_node.find("child::cpee:parameters/cpee:parameters/cpee:#{a.value}").first
      a.value = p.text if p
      puts "Variable for manipulate-block #{a.element.parent.attributes['id']} named #{a.value} not found" unless p
    end
    wf.find("//@output-parameter").each { |a| a.value = "context.result_#{call_node.attributes['id']}['#{a.value}']" } # }}} 
    # Resovle message-parameter {{{
    wf.find("//flow:execute/descendant::flow:input[string(@message-parameter)]").delete_if! do |p|
      var =  call_node.find("child::cpee:parameters/cpee:parameters/cpee:#{p.attributes['message-parameter']}").first
      p.parent.add("input", {"name"=>p.attributes['name'], "variable"=>var.text}) if var
      puts "Variable named #{p.attributes['message-parameter']} could not be resolved" unless var
      true
    end
    wf.find("//flow:execute/descendant::flow:output[string(@message-parameter)]").each do |output|
      output.attributes['message-parameter'] = "context.result_#{call_node.attributes['id']}['#{output.attributes['message-parameter']}']"
    end # }}} 
    # Add repositroy-information to new operation-calls {{{
    wf.find("//flow:execute/descendant::flow:call").each do |call|
      call.attributes['injection_handler'] = call_node.find("string(child::cpee:parameters/cpee:service/cpee:injection_handler)")
    end # }}}
    doc = wf.find("//flow:execute").first.to_doc
    injected.add(XML::Smart.string(doc.transform_with(XML::Smart.open("rng+xsl/rescue2cpee.xsl"))).root.children)
    maintain_class_level(call_node, wf, injected)
  end# }}}

  def maintain_instance_level(wf, call_node, parent_injected, resource_path) # {{{
    blanks = call_node.find('count(ancestor::cpee:*)').to_i
    blanks = ' '*(blanks+3)*2
    op = parent_injected.attributes['serviceoperation'].tr('"', '')
    index = resource_path.tr('/:','__')
    create = "#{blanks}#{parent_injected.attributes['result']}[\"#{resource_path}\"] = RescueHash.new\n"
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
    create << "#{blanks}# Filling the properties-object of the service\n"
    create << "#{blanks}#{parent_injected.attributes['properties']}[\"#{call_node.attributes['oid']}\"][\"#{resource_path}\"] = RescueHash.new\n"
    create << fill_properties(wf.find("//p:properties").first, "#{parent_injected.attributes['properties']}[\"#{call_node.attributes['oid']}\"][\"#{resource_path}\"]", blanks)
    create = call_node.add("manipulate", {"id"=>"create_objects_for_#{call_node.attributes['id']}_service_#{index}", "generated"=>"true"}, create)
    remove = call_node.add("manipulate", {"id"=>"remove_objects_of_#{call_node.attributes['id']}_service_#{index}", "generated"=>"true"}, remove)
    [create, remove]
  end # }}}

  def fill_properties(node, index, blanks) #{{{
    code = ""
    node.find("child::*").each do |e|
      if e.text.strip == ""
        code << "#{blanks}#{index}[\"#{e.name.name}\"] = RescueHash.new\n"
        code << fill_properties(e, "#{index}[\"#{e.name.name}\"]", blanks)
      else
        code << "#{blanks}#{index}[\"#{e.name.name}\"] = \"#{e.text}\"\n"
      end
    end
    code
  end #}}}

  def inject_instance_level(wf, call_node, resource_path, branch, parent_injected)# {{{
    index = resource_path.tr('/:','__')
    op = parent_injected.attributes['serviceoperation'].tr('"', '')
    wf.find('//flow:call[child::flow:templates]').each        {|c| c.attributes['templates-uri'] = "#{rescue_uri}/operations/#{service_operation}/templates/#{c.attributes['id']}" }
    wf.find("//@id").each                                     {|a| a.value = call_node.attributes['id']+'__'+index+'__'+a.value }
    wf.find("//@endpoint").each                               {|a| a.value = call_node.attributes['id']+'__'+index+'__'+a.value }
    wf.find("//flow:call/@wsdl").each                         {|a| a.value = call_node.attributes['id']+'__'+index+'__'+a.value }
    wf.find("//flow:#{op}/descendant::flow:*/@variable").each {|a| a.value = "context.#{call_node.attributes['id']}__#{index}__#{a.value}"}
    wf.find("//flow:#{op}/descendant::flow:*/@test").each     {|a| a.value = "context.#{call_node.attributes['id']}__#{index}__#{a.value}"}
    wf.find("//flow:#{op}/descendant::flow:*/@context").each  {|a| a.value = "context.#{call_node.attributes['id']}__#{index}__#{a.value}"}
    wf.find("//flow:#{op}/descendant::flow:*/@input-parameter").each do |a| 
      p = call_node.find("child::cpee:parameters/cpee:parameters/cpee:#{a.value}").first
      a.value = p.nil? ? "\"not found\"" : p.text 
    end
    wf.find("//flow:#{op}/descendant::flow:*/@output-parameter").each { |a| a.value = "#{parent_injected.attributes['result']}['#{resource_path}']['#{a.value}']" }
    # Resovle message-parameter {{{
    wf.find("//flow:#{op}/descendant::flow:input[string(@message-parameter)]").delete_if! do |p|
      var = call_node.find("child::cpee:parameters/cpee:parameters/cpee:#{p.attributes['message-parameter']}").first
      p.parent.add("input", {"name"=>p.attributes['name'], "variable"=>var.text}) if var 
      true
    end
    wf.find("//flow:#{op}/descendant::flow:output[string(@message-parameter)]").each do |p|
      p.attributes['message-parameter'] = "#{parent_injected.attributes['result']}['#{resource_path}']['#{p.attributes['message-parameter']}']" if  parent_injected.attributes['result']
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
    return unless status == 200
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
      call_node.find("ancestor::cpee:group[@type='injection']/cpee:constraints").each do |cons|
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
    !s.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/).nil?
  end#}}}

  def check_constraint(con, cpee_client, wf) #{{{
# TODO: get context-variables once and store it in an instance-variable
    xpath = ""
    value1 = con.attributes.include?('value') ? con.attributes['value'] : ""
    if con.attributes.include?('variable')
      status, resp = cpee_client.resource("properties/values/context-variables/#{con.attributes['variable']}").get
      unless status == 200
        puts "Could not find variable named #{con.attributes['variable']}"
        return false
      end
      value1 = XML::Smart.string(resp[0].value.read)
      value1 = ActiveSupport::JSON::decode(value1.find("string(p:value)",{"p"=>"http://riddl.org/ns/common-patterns/properties/1.0"}))
    end
    con.attributes['xpath'].split('/').each {|p| xpath << "p:#{p}/"}
    xpath.chop! # remove trailing '/'
    value2 = ActiveSupport::JSON::decode(wf.find("string(//p:properties/#{xpath})"))
    if value1.class == String && value2.class == String
      value2.strip.send(con.attributes['comparator'], value1.strip)
    else
      value2.send(con.attributes['comparator'], value1 )
    end
  end#}}} 
end
