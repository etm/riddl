module Riddl
  module Handlers
    class XMLSchema < Riddl::Handlers::Implementation
      def in(what,hinfo)
        XML::Smart.open(what).validate_against(XML::Smart.open(hinfo)) rescue false
      end
      def out(what,hinfo)
        in(what,hinfo)
      end
    end
  end  
end  

Riddl::Handlers::add("http://riddl.org/ns/handlers/xmlschema",Riddl::Handlers::XMLSchema)
