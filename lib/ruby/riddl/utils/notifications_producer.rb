module Riddl
  module Utils
    module Notifications

      module Producer

        def self::implementation(backend,handler=nil,details=:production)
          unless handler.nil? || (handler.is_a? Riddl::Utils::Notifications::Producer::HandlerBase)
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

        class HandlerBase #{{{
          def initialize(data)
            @data = data
            @key = nil
            @topics = []
          end
          def key(k)
            @key = k
            self
          end
          def topics(t)
            @topics = t
            self
          end
          def ws_open(socket); end
          def ws_close; end
          def ws_message(socket,data); end
          def create; end
          def delete; end
          def update; end
        end #}}}

        class Backend #{{{
          attr_reader :topics

          class Sub #{{{
            def initialize(name)
              @name = name
            end
            def modify(&block)
              XML::Smart.modify(@name,"<subscription xmlns='http://riddl.org/ns/common-patterns/notifications-producer/1.0'/>") do |doc|
                doc.register_namespace 'n', 'http://riddl.org/ns/common-patterns/notifications-producer/1.0'
                block.call doc
              end
            end
            def delete
              FileUtils::rm_rf(File.dirname(@name))
            end
            def to_s
              File.read(@name)
            end
            def read(&block)
              XML::Smart.open_unprotected(@name) do |doc|
                doc.register_namespace 'n', 'http://riddl.org/ns/common-patterns/notifications-producer/1.0'
                block.call doc
              end
            end
          end #}}}

          class Subs #{{{
            def initialize(target)
              @target = target
            end

            def each(&block)
              keys.each do |key|
                f = @target + '/' + key + '/subscription.xml'
                block.call Sub.new(f), key if File.exists? f
              end
            end

            def include?(key)
              f = @target + '/' + key + '/subscription.xml'
              File.exists?(f)
            end

            def [](key)
              f = @target + '/' + key + '/subscription.xml'
              File.exists?(f) ? Sub.new(f) : nil
            end

            def create(&block)
              key = nil
              begin
                continue = true
                key      = Digest::MD5.hexdigest(Kernel::rand().to_s)
                Dir.mkdir(@target + '/' + key) rescue continue = false
              end until continue
              producer_secret = Digest::MD5.hexdigest(Kernel::rand().to_s)
              consumer_secret = Digest::MD5.hexdigest(Kernel::rand().to_s)
              File.open(@target + '/' + key + '/producer-secret','w') { |f| f.write producer_secret }
              File.open(@target + '/' + key + '/consumer-secret','w') { |f| f.write consumer_secret }
              XML::Smart::modify(@target + '/' + key + '/subscription.xml',"<subscription xmlns='http://riddl.org/ns/common-patterns/notifications-producer/1.0'/>") do |doc|
                doc.register_namespace 'n', 'http://riddl.org/ns/common-patterns/notifications-producer/1.0'
                block.call doc, key
              end
              [key, producer_secret, consumer_secret]
            end

            def keys
              if File.directory?(@target)
                Dir[@target + '/*'].map do |d|
                  File.directory?(d) ? File.basename(d) : nil
                end.compact
              else
                []
              end
            end
          end #}}}

          def initialize(topics,target,init=nil)
            @target = target.gsub(/^\/+/,'/')


            if init and not File.exists?(@target)
              FileUtils::cp_r init, @target
            else
              FileUtils::mkdir_p(@target) unless File.exists?(@target)
            end

            raise "topics file not found" unless File.exists?(topics)
            @topics = XML::Smart.open_unprotected(topics.gsub(/^\/+/,'/'))
            @topics.register_namespace 'n', 'http://riddl.org/ns/common-patterns/notifications-producer/1.0'

            subscriptions.each do |sub,key|
              sub.read do |doc|
                if doc.find('/*[@url]').empty?
                  sub.delete
                end
              end
            end
          end

          def subscriptions
            Subs.new(@target)
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
              backend.subscriptions.each do |sub,key|
                sub.read do |doc|
                  if doc.root.attributes['url']
                    ret.root.add('subscription', :id => key, :url => doc.root.attributes['url'])
                  else
                    ret.root.add('subscription', :id => key)
                  end
                end
              end
              ret.to_s
            end
          end
        end #}}}

        class Subscription < Riddl::Implementation #{{{
          def response
            backend = @a[0]
            if(backend.subscriptions.include?(@r.last))
              Riddl::Parameter::Complex.new("subscription","text/xml") do
                backend.subscriptions[@r.last].to_s
              end
            else
              @status = 404
            end
          end
        end #}}}

        class CreateSubscription < Riddl::Implementation #{{{
          def response
            backend = @a[0]
            handler = @a[1]

            url = @p[0].name == 'url' ? @p.shift.value : nil

            topics = []
            key, consumer_secret, producer_secret = backend.subscriptions.create do |doc,key|
              doc.root.attributes['url'] = url if url
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

            handler.key(key).topics(topics).create unless handler.nil?
            [
              Riddl::Parameter::Simple.new('key',key),
              Riddl::Parameter::Simple.new('producer-secret',producer_secret),
              Riddl::Parameter::Simple.new('consumer-secret',consumer_secret)
            ]
          end
        end #}}}

        class DeleteSubscription < Riddl::Implementation #{{{
          def response
            backend = @a[0]
            handler = @a[1]
            key     = @r.last

            backend.subscriptions[key].delete
            handler.key(key).delete unless handler.nil?
            return
          end
        end #}}}

        class UpdateSubscription < Riddl::Implementation #{{{
          def response
            backend = @a[0]
            handler = @a[1]
            key     = @r.last

            url  = @p[0].name == 'url' ? @p.shift.value : nil

            # TODO check if message is valid (with producer secret)
            unless backend.subscriptions[key]
              @status = 404
              return # subscription not found
            end

            topics = []
            backend.subscriptions[key].modify do |doc|
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

            handler.key(key).topics(topics).update unless handler.nil?
            nil
          end
        end #}}}

        class WS < Riddl::WebSocketImplementation #{{{
          def onopen
            @backend = @a[0]
            @handler = @a[1]
            @key     = @r[-2]
            @handler.key(@key).ws_open(self) unless @handler.nil?
          end

          def onmessage(data)
            @handler.key(@key).ws_message(data) unless @handler.nil?
          end

          def onclose
            @handler.key(@key).ws_close() unless @handler.nil?
          end
        end #}}}

      end

    end
  end
end
