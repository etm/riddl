module Riddl
  module Utils
    module Notifications

      module Producer
      
        def self::implementation(backend,handler=nil,details=:production) 
          unless handler.nil? || (handler.class == Class && handler.superclass == Riddl::Utils::Notifications::Producer::HandlerBase)
            raise "handler not a subclass of HandlerBase"
          end
          Proc.new do
            on resource "notifications" do
              run Riddl::Utils::Notifications::Producer::Overview if get
              on resource "topics" do
                run Riddl::Utils::Notifications::Producer::Topics, backend if get
              end
              on resource "subscriptions" do
                run Riddl::Utils::Notifications::Producer::Subscriptions, backend, details if get
                run Riddl::Utils::Notifications::Producer::CreateSubscription, backend, handler if post 'subscribe'
                on resource do
                  run Riddl::Utils::Notifications::Producer::Subscription, backend, details if get 'request'
                  run Riddl::Utils::Notifications::Producer::UpdateSubscription, backend, handler if put 'details'
                  run Riddl::Utils::Notifications::Producer::DeleteSubscription, backend, handler if delete 'delete'
                  on resource 'ws' do
                    run Riddl::Utils::Notifications::Producer::WS, backend, handler if websocket
                  end
                end
              end
            end  
          end
        end  
      
        class HandlerBase
          def initialize(backend,key,topics)
            @backend = backend
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

        class Backend #{{{
          attr_reader :topics, :id, :target

          def initialize(id,topics,target)
            @id = id 
            @target = target.gsub(/^\/+/,'/')

            raise "topics file not found" unless File.exists?(topics)
            @topics = XML::Smart.open_unprotected(topics.gsub(/^\/+/,'/'))
            @topics.register_namespace 'n', 'xmlns='http://riddl.org/ns/common-patterns/notifications-producer/1.0'

            @mutex = Mutex.new
          end  

          def persist
            @subscriptions.save_as(@target)
          end
          protected :persist

          def modify(&block)
            tdoc = @subscriptions.root.to_doc
            tdoc.register_namespace 'n', 'xmlns='http://riddl.org/ns/common-patterns/notifications-producer/1.0'
            @mutex.synchronize do
              block.call @subscriptions
              self.persist
            end
          end
        end #}}}

        class Overview < Riddl::Implementation #{{{ 
          def response
            Riddl::Parameter::Complex.new("overview","text/xml") do
              <<-END
                <overview xmlns='http://riddl.org/ns/common-patterns/notifications-producer/1.0'>
                  <topics/>
                  <subscriptions/>
                </overview>
              END
            end

          end
        end #}}}
        
        class Topics < Riddl::Implementation #{{{
          def response
            backend = @a[0]
            Riddl::Parameter::Complex.new("overview","text/xml") do
              backend.topics.to_s
            end
          end
        end #}}}
        
        class Subscriptions < Riddl::Implementation #{{{
          def response
            backend = @a[0]
            details = @a[1]
            Riddl::Parameter::Complex.new("subscriptions","text/xml") do
              ret = XML::Smart::string <<-END
                <subscriptions details='#{details}' xmlns='http://riddl.org/ns/common-patterns/notifications-producer/1.0'/>
              END
              Dir[data + "/*"].each do |d|
                if File.directory?(d)
                  XML::Smart.open_unprotected(d + "/subscription.xml") do |doc|
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
            Riddl::Parameter::Complex.new("subscription","text/xml") do
              ret  = XML::Smart.open_unprotected(data + "/" + @r.last + "/subscription.xml").to_s
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
              key      = Digest::MD5.hexdigest(Kernel::rand().to_s)
              Dir.mkdir(data + '/' + key) rescue continue = false
            end until continue
            producer_secret = Digest::MD5.hexdigest(Kernel::rand().to_s)
            consumer_secret = Digest::MD5.hexdigest(Kernel::rand().to_s)

            File.open(data + '/' + key + '/producer-secret','w') { |f| f.write producer_secret }
            File.open(data + '/' + key + '/consumer-secret','w') { |f| f.write consumer_secret }

            topics = []
            XML::Smart::modify(data + '/' + key + '/subscription.xml',"<subscription #{url ? "url='#{url}' " : ''} xmlns='http://riddl.org/ns/common-patterns/notifications-producer/1.0'/>") do |doc|
              doc.register_namespace 'n', 'http://riddl.org/ns/common-patterns/notifications-producer/1.0'
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

            handler.new(data,key,topics).create unless handler.nil?
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
            handler.new(data,key,nil).delete unless handler.nil?
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
              doc.register_namespace 'n', 'http://riddl.org/ns/common-patterns/notifications-producer/1.0'
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

            handler.new(data,key,topics).update unless handler.nil?
            nil
          end
        end #}}}
                  
        class WS < Riddl::WebSocketImplementation #{{{
          def onopen
            @data    = @a[0]
            @handler = @a[1]
            @key     = @r[-2]
            @handler.new(@data,@key,[]).ws_open(self) unless handler.nil?
          end

          def onmessage(data)
            @handler.new(@data,@key,[]).ws_message(self,data) unless handler.nil?
          end

          def onclose
            @handler.new(@data,@key,[]).ws_close() unless handler.nil?
          end
        end #}}}
        
      end  

    end
  end
end
