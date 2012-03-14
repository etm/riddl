module Riddl
  module Utils
    module Description

      class XML < Riddl::Implementation
        def response
          return Riddl::Parameter::Complex.new("riddl-description","text/xml",@a[0])
        end
      end
      
    end
  end
end
