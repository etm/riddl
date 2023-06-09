module Riddl
  module Handlers
    class XMLSchema < Riddl::Handlers::Implementation
      def self::handle(what,hinfo)
        w = if what.class == Riddl::Parameter::Tempfile || what.class == File
          XML::Smart.open_unprotected(what)
        else  
          XML::Smart.string(what)
        end  
        w.validate_against(XML::Smart.string(hinfo)) rescue false
      end
    end
  end  
end  

Riddl::Handlers::add("http://riddl.org/ns/handlers/xmlschema",Riddl::Handlers::XMLSchema)
