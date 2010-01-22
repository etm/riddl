module Riddl
  module Utils
    module Notification

      module Provider
      
        def self::implementation(data,xsls,details=:production) 
          if !File.exists?(data) || !File.directory?(data)
            raise "data directory #{data} no found"
          end
          lambda {
            run Riddl::Utils::Notification::Provider::Overview, xsls[:overview] if get
            on resource "topics" do
              run Riddl::Utils::Notification::Provider::Topics, data, xsls[:topics] if get
            end
            on resource "subscriptions" do
              run Riddl::Utils::Notification::Provider::Subscriptions, data, xsls[:subscriptions], details if get
              run Riddl::Utils::Notification::Provider::CreateSubscription, data if post
            end
          }
        end  

        class Overview < Riddl::Implementation #{{{ 
          def response
            Riddl::Parameter::Complex.new("overview","text/xml") do
              ret = XML::Smart::string <<-END
                #{@a[0] ? "<?xml-stylesheet href=\"#{@a[0]}\" type=\"text/xsl\"?>" : ''}
                <overview xmlns='http://riddl.org/ns/common-patterns/notification-producer/1.0'>
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
                <subscriptions information='#{details}' xmlns='http://riddl.org/ns/common-patterns/notification-producer/1.0'/>
              END
              Dir[data + "/*"].each do |d|
                if File.directory?(d)
                  ret.root.add('subscription', :id => File.basename(d))
                end  
              end
              ret.to_s
            end
          end
        end #}}}
       
       class CreateSubscription < Riddl::Implementation #{{{
          def response
            data = @a[0]
            url  = @p.shift
            key  = nil
            begin
              continue = true
              key      = Digest::MD5.hexdigest(rand(Time.now).to_s)
              Dir.mkdir(data + '/' + key) rescue continue = false
            end until continue
            producer-secret = Digest::MD5.hexdigest(rand(Time.now).to_s)
            consumer-secret = Digest::MD5.hexdigest(rand(Time.now).to_s)

            File.open(data + '/' + key + '/producer-secret','w') { |f| f.write producer-secret }
            File.open(data + '/' + key + '/consumer-secret','w') { |f| f.write consumer-secret }

            xml = <<-END
              #{xsl ? "<?xml-stylesheet href=\"#{xsl}\" type=\"text/xsl\"?>" : ''}
              <subscription url='#{url}' last-producer-id='0' last-consumer-id='0' xmlns='http://riddl.org/ns/common-patterns/notification-producer/1.0'/>
            END
            XML::Smart::modify(data + '/' + key + '/subscription.xml',xml) do |doc|
              while @p.length > 0
                topic = @p.shift
                events = @p.shift.split(',')
                t = doc.root.add('topic', :id => topic)
                events.each do |e|
                  t.add('event', e)
                end
                doc.root.add
              end
              ret.to_s
            end  
            [
              Riddl::Parameter::Simple.new('key',key),
              Riddl::Parameter::Simple.new('producer-secret',producer-secret),
              Riddl::Parameter::Simple.new('consumer-secret',consumer-secret)
            ]  
          end
        end #}}}

      end  

    end
  end
end
