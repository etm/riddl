require File.expand_path(File.dirname(__FILE__) + '/../client')

module Riddl
  module Utils
    module Declaration

      class Description < Riddl::Implementation
        def response
          return Riddl::Parameter::Complex.new("riddl-description","text/xml",@a[0])
        end
      end

      class Orchestrate < Riddl::Implementation
        def response
          facade = Riddl::Client.facade(@a[0])

          path = facade.resource "/" + @r.join('/')
          status, result = path.request @m => @p
          @status = status
          result
        end
      end
      
    end
  end
end