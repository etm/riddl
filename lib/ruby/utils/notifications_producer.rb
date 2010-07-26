module Riddl
  module Utils
    module Notifications

      module Producer
      
        def self::implementation(data,xsls,handler,details=:production) 
          unless handler.class == Class && handler.superclass == Riddl::Utils::Notifications::Producer::HandlerBase
            raise "handler not a subclass of HandlerBase"
          end
          if !File.exists?(data) || !File.directory?(data)
            raise "data directory #{data} no found"
          end
          lambda {
            run Riddl::Utils::Notifications::Producer::Overview, xsls[:overview] if get
            on resource "topics" do
              run Riddl::Utils::Notifications::Producer::Topics, data, xsls[:topics] if get
            end
            on resource "subscriptions" do
              run Riddl::Utils::Notifications::Producer::Subscriptions, data, xsls[:subscriptions], details if get
              run Riddl::Utils::Notifications::Producer::CreateSubscription, data, handler if post 'subscribe'
              on resource do
                run Riddl::Utils::Notifications::Producer::Subscription, data, xsls[:subscription], details if get 'request'
                run Riddl::Utils::Notifications::Producer::UpdateSubscription, data, handler if put 'details'
                run Riddl::Utils::Notifications::Producer::DeleteSubscription, data, handler if delete 'delete'
                on resource 'ws' do
                  run Riddl::Utils::Notifications::Producer::WS, data, handler if websocket
                end
              end
            end
          }
        end  
      
        class HandlerBase
          def initialize(notifications,key,topics)
            @notifications = notifications
            @key = key
            @topics = topics
          end
          def ws_open(socket); end
          def ws_close; end
          def ws_message(socket,data); end
          def create; end
          def delete; end
          def update; end
        end

        class Overview < Riddl::Implementation #{{{ 
          def response
            Riddl::Parameter::Complex.new("overview","text/xml") do
              ret = XML::Smart::string <<-END
                #{@a[0] ? "<?xml-stylesheet href=\"#{@a[0]}\" type=\"text/xsl\"?>" : ''}
                <overview xmlns='http://riddl.org/ns/common-patterns/notifications-producer/1.0'>
                  <topics/>
                  <subscriptions/>
                </overview>
              END
              ret.to_s
            end
          end
        end #}}}
        
        class Topics < Riddl::Implementation #{{{
          def response
            data = @a[0]
            xsl  = @a[1]
            Riddl::Parameter::Complex.new("overview","text/xml") do
              ret  = XML::Smart::open(data + "/topics.xml").to_s
              xsl ? ret.sub(/\?>\s*\r?\n/,"?>\n<?xml-stylesheet href=\"xsl\" type=\"text/xsl\"?>\n") : ret
            end
          end
        end #}}}
        
        class Subscriptions < Riddl::Implementation #{{{
          def response
            data    = @a[0]
            xsl     = @a[1]
            details = @a[2]
            Riddl::Parameter::Complex.new("subscriptions","text/xml") do
              ret = XML::Smart::string <<-END
                #{xsl ? "<?xml-stylesheet href=\"#{xsl}\" type=\"text/xsl\"?>" : ''}
                <subscriptions details='#{details}' xmlns='http://riddl.org/ns/common-patterns/notifications-producer/1.0'/>
              END
              Dir[data + "/*"].each do |d|
                if File.directory?(d)
                  XML::Smart::open(d + "/subscription.xml") do |doc|
                    if doc.root.attributes['url']
                      ret.root.add('subscription', :id => File.basename(d), :url => doc.root.attributes['url'])
                    else  
                      ret.root.add('subscription', :id => File.basename(d))
                    end  
                  end  
                end  
              end
              ret.to_s
            end
          end
        end #}}}
       
        class Subscription < Riddl::Implementation #{{{
          def response
            data    = @a[0]
            xsl     = @a[1]
            Riddl::Parameter::Complex.new("subscription","text/xml") do
              ret  = XML::Smart::open(data + "/" + @r.last + "/subscription.xml").to_s
              xsl ? ret.sub(/\?>\s*\r?\n/,"?>\n<?xml-stylesheet href=\"xsl\" type=\"text/xsl\"?>\n") : ret
            end
          end
        end #}}}
        
        class CreateSubscription < Riddl::Implementation #{{{
          def response
            data    = @a[0]
            handler = @a[1]

            url  = @p[0].name == 'url' ? @p.shift.value : nil
            key  = nil
            begin
              continue = true
              key      = Digest::MD5.hexdigest(rand(Time.now).to_s)
              Dir.mkdir(data + '/' + key) rescue continue = false
            end until continue
            producer_secret = Digest::MD5.hexdigest(rand(Time.now).to_s)
            consumer_secret = Digest::MD5.hexdigest(rand(Time.now).to_s)

            File.open(data + '/' + key + '/producer-secret','w') { |f| f.write producer_secret }
            File.open(data + '/' + key + '/consumer-secret','w') { |f| f.write consumer_secret }

            topics = []
            XML::Smart::modify(data + '/' + key + '/subscription.xml',"<subscription #{url ? "url='#{url}' " : ''} xmlns='http://riddl.org/ns/common-patterns/notifications-producer/1.0'/>") do |doc|
              doc.namespaces = { 'n' => 'http://riddl.org/ns/common-patterns/notifications-producer/1.0' }
              while @p.length > 0
                topic = @p.shift.value
                base = @p.shift
                type = base.name
                items = base.value.split(',')
                t = if topics.include?(topic)
                  doc.find("/n:subscription/n:topic[@id='#{topic}']").first
                else
                  topics << topic
                  doc.root.add('topic', :id => topic)
                end
                items.each do |i|
                  t.add(type[0..-2], i)
                end
              end
            end  

            handler.new(data,key,topics).create
            [
              Riddl::Parameter::Simple.new('key',key),
              Riddl::Parameter::Simple.new('producer-secret',producer_secret),
              Riddl::Parameter::Simple.new('consumer-secret',consumer_secret)
            ]  
          end
        end #}}}

        class DeleteSubscription < Riddl::Implementation #{{{
          def response
            data    = @a[0]
            handler = @a[1]
            key     = @r.last

            FileUtils::rm_rf(data + '/' + key)
            handler.new(data,key,nil).delete
            return
          end
        end #}}}
        
        class UpdateSubscription < Riddl::Implementation #{{{
          def response
            data    = @a[0]
            handler = @a[1]
            key     = @r.last

            muid = @p.shift.value
            url  = @p[0].name == 'url' ? @p.shift.value : nil

            # TODO check if message is valid (with producer secret)
            if !File.exists?(data + '/' + key + '/subscription.xml')
              raise "subscription #{data + '/' + key} no found"
            end

            topics = []
            XML::Smart::modify(data + '/' + key + '/subscription.xml') do |doc|
              doc.namespaces = { 'n' => 'http://riddl.org/ns/common-patterns/notifications-producer/1.0' }
              if url.nil?
                doc.find('/n:subscription/@url').delete_all!
              else
                doc.root.attributes['url'] = url
              end
              doc.root.children.delete_all!
              while @p.length > 1
                topic = @p.shift.value
                base = @p.shift
                type = base.name
                items = base.value.split(',')
                t = if topics.include?(topic)
                  doc.find("/n:subscription/n:topic[@id='#{topic}']").first
                else
                  topics << topic
                  doc.root.add('topic', :id => topic)
                end
                items.each do |i|
                  t.add(type[0..-2], i)
                end
              end
            end  

            handler.new(data,key,topics).update
            nil
          end
        end #}}}
                  
        class WS < Riddl::WebSocketImplementation #{{{
          def onopen
            @data    = @a[0]
            @handler = @a[1]
            @key     = @r[-2]
            @handler.new(@data,@key,[]).ws_open(self)
          end

          def onmessage(data)
            @handler.new(@data,@key,[]).ws_message(self,data)
          end

          def onclose
            @handler.new(@data,@key,[]).ws_close()
          end
        end #}}}
        
      end  

    end
  end
end
