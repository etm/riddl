require '../../lib/ruby/client'

class InjectionHandler < Riddl::Implementation
  $injection_queue = Hash.new
  $notification_keys = Array.new
  $registration_semaphore = Mutex.new # this semaphore prevents timing issues when a call leades to an injection which is directly followed by a sync_after event
  $received_stop = Hash.new

  def response
    notification = YAML::load(@p.value('notification')) if @p.value('notification')
    cpee = Riddl::Client.new(notification[:instance]) if notification
    injection_service_uri = "http://#{@env['HTTP_HOST']}/injection/service"
    if @p.length == 0 # Give a Liste of subscirbed injections {{{
      xml = XML::Smart.string('<injection-queue/>')
      $injection_queue.each do |uri, instance|
        instance_node = xml.root.add('instance', {'uri' => uri})
        instance.each do |pos,v|
          instance_node.add(pos.to_s, v.to_s)
        end
      end
      callbacks = xml.root.add('outstanding-callbacks')
      $notification_keys.each {|v| callbacks.add('callback', {'key'=>v})}
      Riddl::Parameter::Complex.new("bla","text/xml", xml.to_s)
# }}}
    elsif @p.value('instance') && (@p.length == 1) # received list pending innjections for a given instance {{{
      xml = XML::Smart.string('<injection-queue/>')
      status, resp = Riddl::Client.new(@p.value('instance')).resource('properties/values/positions').get
      puts "ERROR: Receiving positions failed: #{status}" unless status == 200
      act_pos = XML::Smart.string(resp[0].value.read)
      cpee_pos = xml.root.add('cpee-positions')
      act_pos.find('p:value/p:*', {'p'=>'http://riddl.org/ns/common-patterns/properties/1.0'}).each do |ap|
        cpee_pos.add(ap.name.name, ap.text)
      end
      queue = xml.root.add('queued')
      @p.value('instance')[-1..-1] == '/' ? inst = @p.value('instance').chop : inst = @p.value('instance')
      $injection_queue[inst].each do |position, v|
        queue.add(position.to_s, v.to_s)
      end if $injection_queue.key?(inst) 
      callbacks = xml.root.add('outstanding-callbacks')
      $notification_keys.each {|v| callbacks.add('callback', {'key'=>v})}
      Riddl::Parameter::Complex.new("bla","text/xml", xml.to_s)
# }}}
    elsif @p.value('instance') && @p.value('actual-position') && @p.value('new-position') # received list pending innjections for a given instance {{{
       $injection_queue[@p.value('instance')][@p.value('new-position')] = $injection_queue[@p.value('instance')][@p.value('actual-position')]
       $injection_queue[@p.value('instance')].delete(@p.value('actual-position'))
# }}}
    elsif @p.value('vote') == "syncing_after" && @p.value('topic') == "running"# received notification for sync_after {{{
      registered = nil
      $registration_semaphore.synchronize { registered = $notification_keys.include?(@p.value('key')) }
      if registered
        $notification_keys.delete(@p.value('key'))
        status, resp = cpee.resource("notifications/subscriptions/#{@p.value('key')}").delete [
          Riddl::Parameter::Simple.new("message-uid","ralph"),
          Riddl::Parameter::Simple.new("fingerprint-with-producer-secret",Digest::MD5.hexdigest("ralph42"))
        ]
        puts "Injection-handler: ERROR deleting subscription (#{status})" unless status == 200 # Needs to be logged into the CPEE as well 
        unless $injection_queue.include?(notification[:instance])
          $injection_queue[notification[:instance]] = Hash.new
          status, resp = cpee.resource("notifications/subscriptions").post [
            Riddl::Parameter::Simple.new("url", "http://#{@env['HTTP_HOST']}#{@env['PATH_INFO']}"),
            Riddl::Parameter::Simple.new("topic", "properties/state"),
            Riddl::Parameter::Simple.new("events", "change")
          ]
          puts "Injection-handler: ERROR subscribing state/changed (#{status})" unless status == 200 # Needs to be logged into the CPEE as well
        end
        $injection_queue[notification[:instance]][notification[:activity]] = 'at'
        Riddl::Parameter::Simple.new('continue','false')
      else
        Riddl::Parameter::Simple.new('continue','true')
      end
# }}}
    elsif @p.value('event') == "change" && @p.value('topic') == "properties/state"# received notification for instance stopped{{{
      unless notification[:state] != :stopped
        $registration_semaphore.synchronize { 
          return if $received_stop.include?(notification[:instance]) 
          $received_stop[notification[:instance]] = true 
        }
        status, resp = cpee.resource("notifications/subscriptions/#{@p.value('key')}").delete [
          Riddl::Parameter::Simple.new("message-uid","ralph"),
          Riddl::Parameter::Simple.new("fingerprint-with-producer-secret",Digest::MD5.hexdigest("ralph42"))
        ]
        puts "Injection-handler: ERROR deleting subscription (#{status})" unless status == 200 # Needs to be logged into the CPEE as well 
        changed_positions = Array.new
        queue = $injection_queue[notification[:instance]].dup
        # $injection_queue[notification[:instance]].each do |position, state|
        queue.each do |position, state|
          changed_positions.each { |p| position = p[:new] if position.to_s == p[:old]}
          status, resp = Riddl::Client.new(injection_service_uri).post [
            Riddl::Parameter::Simple.new('position', position),
            Riddl::Parameter::Simple.new('instance', notification[:instance]),
            Riddl::Parameter::Simple.new('handler', "http://#{@env['HTTP_HOST']}#{@env['PATH_INFO']}")
          ]
          puts "Injection-handler: ERROR injection failed with status: #{status}" unless status == 200
          if resp.value('positions')
            xml = XML::Smart.string(resp.value('positions').read)
            xml.find('/positions/*').each do |p|
              changed_positions << {:old => p.name.name, :new => p.attributes['new'], :state => p.text}
              $injection_queue[notification[:instance]][p.attributes['new'].to_sym] = 'at' if $injection_queue[notification[:instance]].key?(p.name.name.to_sym)
              $injection_queue[notification[:instance]].delete(p.name.name.to_sym)
            end
          end
        end
        # Setting positions
        status, resp = cpee.resource("properties/values/positions").get # {{{
        puts "ERROR: Receiving positions failed #{status}" unless status == 200
        positions = XML::Smart.string(resp[0].value.read)
        positions.namespaces['p'] = 'http://riddl.org/ns/common-patterns/properties/1.0' # }}}
        changed_positions.each { |p| positions.find("p:value/p:#{p[:old]}").delete_if!{true}} # Update positions {{{
        positions.find('p:value/p:*').each { |node| node.text = 'after'}
        changed_positions.each { |p| positions.root.add(p[:new], p[:state])}
        status, resp = cpee.resource("properties/values/positions").put [Riddl::Parameter::Simple.new("content", positions.root.dump)] 
        puts "Injection-handler: ERROR setting positions (#{status})" unless status == 200 # Needs to be logged into the CPEE as well # }}}
        # Restarting the instance
        status, resp = cpee.resource("properties/values/state").put [Riddl::Parameter::Simple.new("value", "running")]
        $injection_queue.delete(notification[:instance])
        $received_stop.delete(notification[:instance])
      end
# }}} 
    elsif @p.value('notification-key' ) # received subsription for sync_after {{{
      $registration_semaphore.synchronize { $notification_keys << @p.value('notification-key') }
      puts "\t=== Injection-handler: Receiving key of sync_after notification #{@p.value('notification-key')}" # without this puts the call back may come to fast will not be subscribed then      
    # }}}
    else # some other request
      puts "\t=== Injection-handler: ERROR: unkonwn request"
      @p.each {|param| puts param.inspect }
      @status = 404
    end
  end#}}}
end