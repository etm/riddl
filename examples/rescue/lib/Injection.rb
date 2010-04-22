require '../../lib/ruby/client'

class Injection < Riddl::Implementation
  def response
    Thread.new {Thread.pass; inject(@p[0].value, @p[1].value, @p[2].value);}
    Riddl::Parameter::Simple.new("injecting", "true")
  end
  def inject(position, cpee_uri, rescue_uri)
    cpee_client = Riddl::Client.new(cpee_uri)
    rescue_client = Riddl::Client.new(rescue_uri)

    # Get description
    status, resp = cpee_client.resource("/properties/values/description").get
    if status != 200
      puts "Error receiving description at #{cpee_uri}/properties/values/description: #{status}"
      @status = 404
      return
    end
    description = XML::Smart.string(resp[0].value.read)
    call_node = description.find("//flow:call[@id = '#{position}']", {"flow" => "http://rescue.org/ns/controlflow/0.2"}).first
    blind = XML::Smart.string("<injected id='#{call_node.attributes['id']}'/>").root
    status, resp = cpee_client.resource("/properties/values/endpoints/#{call_node.attributes['endpoint']}").get
    if status != 200
      puts "Error receiving endpoint at #{cpee_uri}/properties/values/endpoints/#{call_node.attributes['endpoint']}: #{status}"
      @status = 404
      return
    end
    resource_path = resp[0].value
    # Get wf
    status, resp = rescue_client.resource("#{resource_path.split('/')[0]}/operations/#{call_node.attributes['service-operation']}").get
    if status != 200
      puts "Error receiving wf at #{rescue_uri}/#{resource_path.split('/')[0]}/operations/#{call_node.attributes['service-operation']}: #{status}"
      @status = 404
      return
    end
    wf = XML::Smart.string(resp[0].value.read)
    # Adapt wf (change id's, resolve messages)
    wf.find("//@id", {"flow" => "http://rescue.org/ns/controlflow/0.2"}).each {|a| a.value = call_node.attributes['id']+'__'+a.value}
    #blind.add(wf.find("//domain:operation/domain:#{call_node.attributes['state-controlflow']}/flow:*", {"flow" => "http://rescue.org/ns/controlflow/0.2", "domain"=>"http://rescue.org/ns/domain/0.2"}))
    wf.find("//domain:operation/domain:#{call_node.attributes['state-controlflow']}/flow:*", {"flow" => "http://rescue.org/ns/controlflow/0.2", "domain"=>"http://rescue.org/ns/domain/0.2"}).reverse_each do |node|
      repo_ep =  call_node.find("child::flow:repository",  {"flow" => "http://rescue.org/ns/controlflow/0.2"}).first.attributes['endpoint']
      node.add("repository", {"endpoint"=> repo_ep}) if node.attributes['service-operation'] != nil
      call_node.add_after(node)
    end
    # Inject wf
    #call_node.add_after(blind)
puts description
    # Stop instance
puts "=== stoping instance"
    status, resp = cpee_client.resource("/properties/values/state").put [Riddl::Parameter::Simple.new("value", "stopping")]
    puts "=== stopping #{status}"
    # Set description
puts "=== set description"
    status, resp = cpee_client.resource("/properties/values/description").put [Riddl::Parameter::Simple.new("value", description.root.dump)]
    puts "=== seting description #{status}"
    # Re-start instance
puts "=== start instance"
    status, resp = cpee_client.resource("/properties/values/state").put [Riddl::Parameter::Simple.new("value", "running")]
    puts "=== starting #{status}"
  end
end
