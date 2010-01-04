module Riddl
  module Utils
    module Declaration

      class Description < Riddl::Implementation #{{{
        def response
          return Riddl::Parameter::Complex.new("riddl-description","text/xml",@a[0])
        end
      end #}}}

      class Orchestrate < Riddl::Implementation #{{{
        def response
          facade = Riddl::Client.facade(@a[0])

          path = facade.resource "/" + @r.join('/')
          status, result = path.request @m => @p
          @status = status
          result
        end
      end #}}} 
      
      def self::helper(fdeclaration,include_description)
        riddl = Riddl::Wrapper.new(fdeclaration)
        unless riddl.declaration?
          puts 'Not a RIDDL declaration.' 
          exit
        end
        unless riddl.validate!
          puts "Does not conform to specification."
          exit
        end

        d = riddl.declaration
        s = d.description_xml(true)

        [riddl,s]
      end
        
    end
  end
end
