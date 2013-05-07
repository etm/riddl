module Riddl
  module Utils
    module Description

      class XML < Riddl::Implementation
        def response
          return Riddl::Parameter::Complex.new("riddl-description","text/xml",@a[0])
        end
      end

      class Call < Riddl::Implementation
        def response
          client = Riddl::Client.new(@a[0],@a[1])

          path = client.resource "/" + @a[2]
          status, result = path.request @m => @p
          @status = status
          result
        end
      end
      
    end
  end
end
