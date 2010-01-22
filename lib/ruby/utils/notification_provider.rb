module Riddl
  module Utils
    module Notification

      module Provider
      
        def self::implementation(data,xsls)
          lambda {
            run Riddl::Utils::Notification::Provider::Overview, xsls[:overview] if get
            on resource "topics" do
              run Riddl::Utils::Notification::Provider::Topics, data, xsls[:topics] if get
            end
          }
        end  

        class Overview < Riddl::Implementation
          def response
            Riddl::Parameter::Complex.new("overview","text/xml") do
              i = XML::Smart::string <<-END
                #{@a[0] ? "<?xml-stylesheet href=\"#{@a[0]}\" type=\"text/xsl\"?>" : ''}
                <overview xmlns='http://riddl.org/ns/common-patterns/notification-producer/1.0'>
                  <topics/>
                  <subscriptions/>
                </overview>
              END
              i.to_s
            end
          end
        end
        
        class Topics < Riddl::Implementation
          def response
            Riddl::Parameter::Complex.new("overview","text/xml") do
              data = @a[0]
              p data
              xsl  = @a[1]
              ret  = XML::Smart::open(data + "/topics.xml").to_s
              xsl ? ret.sub(/\?>\s*\r?\n/,"?>\n<?xml-stylesheet href=\"xsl\" type=\"text/xsl\"?>\n") : ret
            end
          end
        end

      end  

    end
  end
end
