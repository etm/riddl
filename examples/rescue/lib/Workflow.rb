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
      puts '='*80
      puts "Resolving call: #{call.attributes['id']}"
      endpoints= Hash.new
      blocks = Hash.new
      endpoints[:resource_scope] = call.attributes['endpoint']
      call.find("child::flow:endpoint",  {"flow" => "http://rescue.org/ns/controlflow/0.2"}).each {|ass| endpoints.store(ass.attributes['id'].to_sym, ass.attributes['use'])}
      #puts endpoints.inspect
      resolve_class_call(call, call, endpoints, blocks)
      puts '='*80
    end
    calls.delete_if!{true}
  end

  def to_s
    @__workflow.to_s
  end

  private
  
  def resolve_class_call(call, before_node, endpoints, blocks)
    service_operation = call.attributes['service-operation']
    state_controlflow = call.attributes['state-controlflow']
    endpoints.include?(call.attributes['endpoint'].to_sym) ? ep = endpoints[call.attributes['endpoint'].to_sym] : ep = call.attributes['endpoint']
    endpoint = @__workflow.find("//flow:endpoint[@id='#{ep}']", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).first.text
   
    status, response = @__riddl_client.resource("#{endpoint.split("/")[0]}/operations/#{service_operation}").get
    puts "Error receiving resource #{endpoint.split("/")[0]}/operations/#{service_operation}" if status != 200
    class_workflow = XML::Smart.string(response[0].value.read).find("//domain:#{state_controlflow}//flow:*[name()!='flow:input' and name()!='flow:output']", {"flow"=>"http://rescue.org/ns/controlflow/0.2", "domain"=>"http://rescue.org/ns/domain/0.2"})

    class_workflow.each do |e|
    puts e.dump
      if e.attributes.include?("service-operation")
        so = e.attributes['service-operation']
        sc = e.attributes['state-controlflow']
        if not blocks.include?("#{so}_#{sc}".to_sym)
          puts "Resolve #{e.attributes['id']}"
    blocks["#{service_operation}_#{state_controlflow}".to_sym] = ""
      puts blocks.inspect
          resolve_class_call(e, before_node, endpoints, blocks)
        else
          puts "#{before_node.attributes['id']} - add #{e.attributes['id']}"
          before_node.add_before(e)
        end
        puts "#{before_node.attributes['id']} - Add  #{e.attributes['id']}"
        before_node.add_before(e)
      end
    end
  end
end
