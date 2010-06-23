require '../../lib/ruby/client'

class InjectionHandler < Riddl::Implementation
  $ih_resources = {}
  $ih_instance_locked = {}
  def response
    if @p.value('position') # received subscription-request
      puts "== Injection-handler: received subsription-request"
      resource = Digest::MD5.hexdigest(rand(Time.now).to_s)
      $ih_resources[resource] = @p.value('position')
      puts "\t=== Injection-handler: Created resource: #{resource}"
      @status = 200
      return Riddl::Parameter::Simple.new('id', resource)
    elsif @p.value('instance') # received request for injceting an instance
      if @p.value('operation') == 'lock'
        proceed = ($ih_instance_locked.include?(@p.value('instance')) ? false : true)
        $ih_instance_locked[@p.value('instance')] = "locked"
        puts "== Injection-handler: service asked for request to inject instance #{@p.value('instance')} => proceed: #{proceed}"
        @status = 503 unless proceed # 503: temporary not allowd
      elsif @p.value('operation') == 'release'
        puts "== Injection-handler: service released instance #{@p.value('instance')}"
        $ih_instance_locked.delete(@p.value('instance'))
      else
        puts "Injection-handler: ERROR unknown operation requested"
        puts @p.inspect
        @status = 404
      end
      return Riddl::Parameter::Simple.new("proceed", proceed)
    elsif @p.value('vote') == "syncing_after" && @p.value('topic') == "running"# received notification
      notification = YAML::load(@p.value('notification'))
      puts "== Injection-handler: Received notification for '#{@p.value('vote')}' at position '#{notification[:activity]}'"
      continue = nil
      if $ih_resources.include?(@r[-1]) && $ih_resources[@r[-1]].to_s == notification[:activity].to_s
        puts "\t=== Injection-handler: Position subscribed at this resource => vote continue: false"
        continue = false
        cpee = Riddl::Client.new(notification[:instance])
        subscribe_injection_service(cpee, notification)
        puts "\t=== Injection-handler: Delete subscription for running - syncing_after" 
        status, resp = cpee.resource("notifications/subscriptions/#{@p.value('key')}").delete [
          Riddl::Parameter::Simple.new("message-uid","ralph"),
          Riddl::Parameter::Simple.new("fingerprint-with-producer-secret",Digest::MD5.hexdigest("ralph42"))
        ]
        puts "Injection-handler: ERROR deleting subscription (#{status})" unless status == 200 # Needs to be logged into the CPEE as well
      else
        puts "\t=== Injection-handler: Position not subscribed at this resource => vote continue: true"
        continue = true
      end
    else # some other request
      puts "\t=== Injection-handler: ERROR: unkonwn request"
      puts @p.inpstect
      @status = 404
    end
    Riddl::Parameter::Simple.new("continue",continue)
  end#}}}

  def subscribe_injection_service(cpee, notification) #{{{
    puts "\t=== Injection-handler: Subscribe instance for injection service"
    # This class allows a dynmic distribution to differetn injection service. In theory here could be some logic to decied wich service to use for injection. Cloudify Everything!
    service_uri = "http://localhost:9290/injection/service"
    client = Riddl::Client.new(service_uri)
    status, resp = client.post [
      Riddl::Parameter::Simple.new('position', notification[:activity]), 
      Riddl::Parameter::Simple.new('monitor', "http://localhost:9290/injection/handler")
    ]
    puts "Injection-handler: ERROR creating injection-resource (#{status})" unless status == 200 # Needs to be logged into the CPEE as well
    res_id = resp.value('id')
    puts "\t=== Injection-handler: Subscribing injection-service(#{service_uri}/#{res_id}) for state-changed event"
    status, resp = cpee.resource("notifications/subscriptions").post [
      Riddl::Parameter::Simple.new("url", "#{service_uri}/#{res_id}"),
      Riddl::Parameter::Simple.new("topic", "properties/state"),
      Riddl::Parameter::Simple.new("events", "change")
    ]
    puts "Injection-handler: ERROR subscribing state/changed (#{status})" unless status == 200 # Needs to be logged into the CPEE as well
  end#}}}
end
