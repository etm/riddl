require '../../lib/ruby/client'

$injection_queue = Hash.new
$subscribed_stop = Hash.new

class InjectionHandler < Riddl::Implementation
  def response
    notification = ActiveSupport::JSON::decode(@p.value('notification')) if @p.value('notification')
    cpee = Riddl::Client.new(notification['instance']) if notification
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
      return Riddl::Parameter::Complex.new("bla","text/xml", xml.to_s)
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
      $injection_queue[@p.value('instance')][:activities].each do |position|
        queue.add(position.to_s)
      end if $injection_queue.key?(@p.value('instance')) 
      callbacks = xml.root.add('outstanding-callbacks')
      return Riddl::Parameter::Complex.new("bla","text/xml", xml.to_s)
# }}}
    elsif @p.value('activity') && @p.value('instance') # received subsription for sync_after {{{#
      # Subscribe Injection-Handler to syncing_after 
      $injection_queue[@p.value('instance')] ||= Hash.new
      $injection_queue[@p.value('instance')][:mutex] ||= Mutex.new
      @status = 500
      $injection_queue[@p.value('instance')][:mutex].synchronize do
        if !$injection_queue.has_key?(@p.value('instance')) || ($injection_queue[@p.value('instance')][:sync] != :active && $injection_queue[@p.value('instance')][:sync] != :start)
          cpee = Riddl::Client.new(@p.value('instance'))
          status, resp = cpee.resource("notifications/subscriptions").post [ 
            Riddl::Parameter::Simple.new("url", "http://#{@env['HTTP_HOST']}#{@env['PATH_INFO']}"),
            Riddl::Parameter::Simple.new("topic", "running"),
            Riddl::Parameter::Simple.new("votes", "syncing_after")
          ]
          raise "Subscribtion of #{} at #{cpee_instance} failed with status: #{status}" unless status == 200
          $injection_queue[@p.value('instance')][:key] = resp.value('key') 
          $injection_queue[@p.value('instance')][:sync] = :start
          $injection_queue[@p.value('instance')][:activities] ||= Array.new
        end 
        $injection_queue[@p.value('instance')][:activities] << @p.value('activity')
        @status = 200
      end  
    # }}}
    elsif @p.value('vote') == "syncing_after" && @p.value('topic') == "running"# received notification for sync_after {{{
      $injection_queue[notification['instance']][:mutex].synchronize do
        if $injection_queue[notification['instance']][:activities].include?(notification['activity'])
          if $injection_queue[notification['instance']][:sync] == :start 
            $injection_queue[notification['instance']][:sync] = :active
            status, resp = cpee.resource("notifications/subscriptions").post [
              Riddl::Parameter::Simple.new("url", "http://#{@env['HTTP_HOST']}#{@env['PATH_INFO']}"),
              Riddl::Parameter::Simple.new("topic", "properties/state"),
              Riddl::Parameter::Simple.new("events", "change")
            ]
            puts "Injection-handler: ERROR subscribing state/changed (#{status})" unless status == 200 # Needs to be logged into the CPEE as well
            return Riddl::Parameter::Simple.new('continue','false')
          end  
          if $injection_queue[notification['instance']][:sync] == :active
            return Riddl::Parameter::Simple.new('continue','false')
          end 
        end
        return Riddl::Parameter::Simple.new('continue','true')
      end
# }}}  
    elsif @p.value('event') == "change" && @p.value('topic') == "properties/state"# received notification for instance stopped{{{
      unless notification['state'] != 'stopped'
        status, resp = cpee.resource("properties/values/positions").get # Get positions {{{
        puts "ERROR: Receiving positions failed #{status}" unless status == 200
        positions = XML::Smart.string(resp[0].value.read)
        positions.namespaces['p'] = 'http://riddl.org/ns/common-patterns/properties/1.0' # }}}
        status, resp = cpee.resource("notifications/subscriptions/#{$injection_queue[notification['instance']][:key]}").delete [
          Riddl::Parameter::Simple.new("message-uid","ralph"),
          Riddl::Parameter::Simple.new("fingerprint-with-producer-secret",Digest::MD5.hexdigest("ralph42"))
        ]
        $injection_queue[notification['instance']][:sync] = :finished
        status, resp = cpee.resource("notifications/subscriptions/#{@p.value('key')}").delete [
          Riddl::Parameter::Simple.new("message-uid","ralph"),
          Riddl::Parameter::Simple.new("fingerprint-with-producer-secret",Digest::MD5.hexdigest("ralph42"))
        ]
        puts "Injection-handler: ERROR deleting subscription (#{status})" unless status == 200 # Needs to be logged into the CPEE as well 
# This shoud be an own thread to avoid long pending of the npotificatin request
        changed_positions = Hash.new
        status, resp = cpee.resource('/properties/values/description').get # {{{ Get description
        raise "ERROR: receiving description faild" unless status == 200
        description = resp[0].value.read # }}}
        queue = []
        $injection_queue[notification['instance']][:activities].each {|v| queue << v.dup}
        queue.each do |o_position|
          cp = (changed_positions.include?(o_position) ? changed_positions[o_position][:new] : o_position)
          status, resp = Riddl::Client.new(injection_service_uri).post [
            Riddl::Parameter::Simple.new('position', cp),
            Riddl::Parameter::Simple.new('instance', notification['instance']),
            Riddl::Parameter::Simple.new('handler', "http://#{@env['HTTP_HOST']}#{@env['PATH_INFO']}"),
            Riddl::Parameter::Complex.new('description', 'text/xml', description)
          ]
          puts "Injection-handler: ERROR injection failed with status: #{status}" unless status == 200
          if resp.value('positions')
            xml = XML::Smart.string(resp.value('positions').read)
            xml.find('/positions/*').each do |p|
              name = p.name.name
              changed_positions.each {|k,v| name = k if v[:new] == name }
              changed_positions[name] = {:new => p.attributes['new'], :state => p.text}
              $injection_queue[notification['instance']][:activities].delete(p.name.name)
              $injection_queue[notification['instance']][:activities] << p.attributes['new']
            end
          else
            raise "No posistions received"
          end
          if resp.value('description')
            description = resp.value('description').read
          else
            raise "No description received"
          end
        end
        status, resp = cpee.resource("/properties/values/description").put [Riddl::Parameter::Simple.new("content", "<content>#{description}</content>")] # Set description {{{
        unless status == 200
          puts "ERROR setting description - status: #{status}"
        end # }}} 
        # Setting positions # {{{
        changed_positions.each { |k,v| positions.find("p:value/p:#{k}").delete_if!{true}} # Update positions 
        changed_positions.each { |k,v| positions.root.add(v[:new], v[:state]) if positions.find("//p:#{v[:new]}").first.nil?}
        status, resp = cpee.resource("properties/values/positions").put [Riddl::Parameter::Simple.new("content", positions.root.dump)] 
        puts "ERRO: injecting positions failed (#{status})" unless status == 200
        puts "Injection-handler: ERROR setting positions (#{status})" unless status == 200 # Needs to be logged into the CPEE as well # }}}
        status, resp = cpee.resource("properties/values/state").put [Riddl::Parameter::Simple.new("value", "running")]# Restarting the instance
        $injection_queue.delete(notification['instance'])
      end
      nil
# }}} 
    else # some other request
      puts "\t=== Injection-handler: ERROR: unkonwn request"
      @p.each {|param| puts param.inspect }
      @status = 404
    end
    return
  end#}}}
end
