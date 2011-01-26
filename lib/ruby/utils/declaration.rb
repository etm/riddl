require File.expand_path(File.dirname(__FILE__) + '/../client')

module Riddl
  module Utils
    module Declaration

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
