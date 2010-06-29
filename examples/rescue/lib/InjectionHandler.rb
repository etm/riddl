require '../../lib/ruby/client'

class InjectionHandler < Riddl::Implementation
  $injection_queue = Hash.new
  $notification_keys = Array.new
  $registration_semaphore = Mutex.new # this semaphore prevents timing issues when a call leades to an injection which is directly followed by a sync_after event
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
    elsif @p.value('intstance') && (@p.length == 1) # received list pending innjections for a given instance {{{
      xml = XML::Smart.string('<injection-queue/>')
      $injection_queue[@p.value('instance')].each do |positioni, v|
        xml.root.add(pos.to_s, v.to_s)
      end
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
        puts "== Injection-handler: Received notification for '#{@p.value('vote')}' at position '#{notification[:activity]}'"
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
        puts "\t=== Injection-handler: Callback with key '#{@p.value('key')}' not subscribed"
        Riddl::Parameter::Simple.new('continue','true')
      end
# }}}
    elsif @p.value('event') == "change" && @p.value('topic') == "properties/state"# received notification for instance stopped{{{
      unless notification[:state] != :stopped
        puts "== Injection-handler: #{notification[:instance]} informed about state stopped"
        status, resp = cpee.resource("notifications/subscriptions/#{@p.value('key')}").delete [
          Riddl::Parameter::Simple.new("message-uid","ralph"),
          Riddl::Parameter::Simple.new("fingerprint-with-producer-secret",Digest::MD5.hexdigest("ralph42"))
        ]
        puts "Injection-handler: ERROR deleting subscription (#{status})" unless status == 200 # Needs to be logged into the CPEE as well 
        $injection_queue[notification[:instance]].each do |position, state|
          puts "\t=== Injection-handler: Injecting on position #{position} at instance #{notification[:instance]}"
          status, resp = Riddl::Client.new(injection_service_uri).post [
            Riddl::Parameter::Simple.new('position', position),
            Riddl::Parameter::Simple.new('instance', notification[:instance])
          ]
          puts "Injection-handler: ERROR injection failed with status: #{status}" unless status == 200
          if resp.value('position') == position.to_s
            $injection_queue[notification[:instance]][position] = resp.value('state')
          else
            $injection_queue[notification[:instance]][position] = {:new_position => resp.value('position'), :state => resp.value('state')}
          end
        end
        # Setting positions
        status, resp = cpee.resource('properties/values/positions').get
        puts "Injection-handler: ERROR receiving postions (#{status})" unless status == 200 # Needs to be logged into the CPEE as well 
        positions = XML::Smart.string(resp[0].value.read)
        positions.find('p:value/p:*', {'p'=>'http://riddl.org/ns/common-patterns/properties/1.0'}).each do |pos|
          name = pos.name.name.to_sym
          if  $injection_queue[notification[:instance]].include?(name) # something was injected at this position
            if $injection_queue[notification[:instance]][name].class == String
              pos.text = $injection_queue[notification[:instance]][name]
            elsif $injection_queue[notification[:instance]][name].class == Hash # the position was changed -> e.g. during a loop-onjection
              pos.find('.').delete_if!{true}
              np = positions.root.add( $injection_queue[notification[:instance]][name][:new_position], $injection_queue[notification[:instance]][name][:state])
            end
          else
            pos.text = 'after'
          end
        end
        status, resp = cpee.resource("properties/values/positions").put [Riddl::Parameter::Simple.new("content", positions.root.dump)]
        puts "Injection-handler: ERROR setting positions (#{status})" unless status == 200 # Needs to be logged into the CPEE as well 
        # Restarting the instance
        $injection_queue.delete(notification[:instance])
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
