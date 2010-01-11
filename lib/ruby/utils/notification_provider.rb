module Riddl
  module Utils
    module Notification

      module Provider
      
        def self::implementation(data,xsls)
          lambda {
            run Riddl::Utils::Notification::Provider::Overview, xsls[:overview] if get
          }
        end  

        class Overview < Riddl::Implementation
          def response
            Riddl::Parameter::Complex.new("overview","text/xml") do
              i = XML::Smart::string <<-END
                #{@a[0] ? "<?xml-stylesheet href=\"#{@a[0]}\" type=\"text/xsl\"?>" : ''}
                <overview>
                  <secret/>
                  <topics/>
                  <subscriptions/>
                </overview>
              END
              i.to_s
            end
          end
        end

      end  

    end
  end
end
