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
            details = @a[1]
            Riddl::Parameter::Complex.new("subscriptions","text/xml") do
              ret = XML::Smart::string <<-END
                #{xsl ? "<?xml-stylesheet href=\"#{xsl}\" type=\"text/xsl\"?>" : ''}
                <subscriptions information='#{details}' xmlns='http://riddl.org/ns/common-patterns/notification-producer/1.0'/>
              END
              Dir[data].each do |d|
              end
              ret.to_s
            end
          end
        end #}}}

      end  

    end
  end
end
