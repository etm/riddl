require 'rubygems'
require 'xml/smart'
require '../../lib/ruby/client'

class Workflow
  @__workflow = nil
  @__riddl_client = nil



  def initialize(filename)
    load(filename)
    @__riddl_client = Riddl::Client.new("http://localhost:9290/groups")
  end

  def load(filename)
    @__workflow = XML::Smart.open(filename)
  end

  def resolve_calls()
    calls = @__workflow.find("//flow:call[string(@service-operation)]", {"flow" => "http://rescue.org/ns/controlflow/0.2"})
    calls.each do |call|
      endpoints= Hash.new
      inputs = Hash.new
      outputs = Hash.new
      endpoints[:resource_scope] = call.attributes['endpoint']
      call.find("child::flow:endpoint",  {"flow" => "http://rescue.org/ns/controlflow/0.2"}).each do |e| 
        endpoints.store(e.attributes['id'].to_sym, e.attributes['use'])
      end
      call.find("child::flow:input",  {"flow" => "http://rescue.org/ns/controlflow/0.2"}).each do |i| 
        inputs.store(i.attributes['name'].to_sym, i.attributes['context']) if i.attributes.include?('context')
        inputs.store(i.attributes['name'].to_sym, i.attributes['fix-value']) if i.attributes.include?('fix-value')
      end
      call.find("child::flow:output",  {"flow" => "http://rescue.org/ns/controlflow/0.2"}).each do |o| 
        outputs.store(o.attributes['name'].to_sym, o.attributes['context']) if o.attributes.include?('name')
        outputs.store(o.attributes['property'].to_sym, o.attributes['context']) if o.attributes.include?('property')
      end
      
      call.add_before(resolve_class_call(call.attributes['id'], call, endpoints, inputs, outputs, "#{call.attributes['service-operation']}_#{call.attributes['state-controlflow']}"))
    end
    calls.delete_if!{true}
  end

  def to_s
    @__workflow.to_s
  end

  private
  
  def resolve_class_call(call_id, call, endpoints, inputs, outputs, blocks)
    id = Array.new
    service_operation = call.attributes['service-operation']
    state_controlflow = call.attributes['state-controlflow']
    endpoints.include?(call.attributes['endpoint'].to_sym) ? endpoint = endpoints[call.attributes['endpoint'].to_sym] : endpoint = call.attributes['endpoint']

    puts '='*100
    puts inputs.inspect
    puts outputs.inspect
    puts '='*100

    resource = @__workflow.find("//flow:endpoint[@id='#{endpoint}']", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).first.text.split("/")[0]
    resp = do_riddl_call("#{resource}/operations/#{service_operation}", 200, [])
    
    block = XML::Smart.string(resp[0].value.read)

    calls = block.find("//domain:#{state_controlflow}/flow:call[string(@service-operation)]", {"domain"=>"http://rescue.org/ns/domain/0.2", "flow"=>"http://rescue.org/ns/controlflow/0.2"}) 
    calls.each do |c|
      if blocks.include?(":#{c.attributes['service-operation']}_#{c.attributes['state-controlflow']}") == false
        id << c.attributes['id']
        c.add_before(resolve_class_call("#{c.attributes['id']}", c, endpoints, inputs, outputs, blocks+":#{c.attributes['service-operation']}_#{c.attributes['state-controlflow']}"))
      else
      end
    end
    calls.delete_if!{|c| id.include?(c.attributes['id'])}

    flows = block.find("//domain:#{state_controlflow}/descendant::flow:*", {"domain"=>"http://rescue.org/ns/domain/0.2","flow"=>"http://rescue.org/ns/controlflow/0.2"})
    flows.each do |f|
      f.attributes['id'] = "#{call_id}__#{f.attributes['id']}" if f.attributes.include?('id')
      f.attributes['endpoint'] = endpoints[f.attributes['endpoint'].to_sym] if f.attributes.include?('endpoint') and endpoints.include?(f.attributes['endpoint'].to_sym)
    end
    block.find("//flow:input",  {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).each do |input|
      #resolve_message(input, inputs) if input.attributes.include?('message')
    end
    block.find("//domain:#{state_controlflow}/descendant::flow:*", {"domain"=>"http://rescue.org/ns/domain/0.2","flow"=>"http://rescue.org/ns/controlflow/0.2"}).delete_if!{|f| f.attributes.include?('message')}
    block.find("//domain:#{state_controlflow}/flow:*", {"domain"=>"http://rescue.org/ns/domain/0.2","flow"=>"http://rescue.org/ns/controlflow/0.2"})
  end

  def resolve_message(message, params)
    puts message.parent.attributes['id']
    puts message.parent.attributes['endpoint']
    resource = @__workflow.find("//flow:endpoint[@id='#{message.parent.attributes['endpoint']}']", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).first.text.split("/")[0]
    puts "Message for #{resource}"
    resp = do_riddl_call(resource, 200, [Riddl::Parameter::Simple.new("input", "")])
    XML::Smart.string(resp[0].value.read).find("/rng:element/rng:element", {"rng"=>"http://relaxng.org/ns/structure/1.0"}).each do |param|
      name = param.attributes['name']
      message.parent.add("input", {"name"=>name, "context"=>params[name.to_ysm]})
    end
  end

  def do_riddl_call(resource, expectation, params)
    status, resp = @__riddl_client.resource(resource).get params
    puts "Error receiving information from #{resource} at endpoint:#{resource}" if status != expectation
    resp
  end

  def resolve_message_parameter(parameter)
  end

  def reslove_context(context)
  end

end
