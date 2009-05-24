module Riddl
  module Handlers
    class XMLSchema < Riddl::Handlers::Implementation
      def self::handle(what,hinfo)
        XML::Smart.string(what).validate_against(XML::Smart.string(hinfo)) rescue false
      end
    end
  end  
end  

Riddl::Handlers::add("http://riddl.org/ns/handlers/xmlschema",Riddl::Handlers::XMLSchema)
