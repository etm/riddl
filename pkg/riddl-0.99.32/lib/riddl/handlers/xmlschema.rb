module Riddl
  module Handlers
    class XMLSchema < Riddl::Handlers::Implementation
      def self::handle(what,hinfo)
        # TODO XML Smart should understand ruby filehandles
        if what.class == Riddl::Parameter::Tempfile
          w = what.read
        else  
          w = what
        end  
        XML::Smart.string(w).validate_against(XML::Smart.string(hinfo)) rescue false
      end
    end
  end  
end  

Riddl::Handlers::add("http://riddl.org/ns/handlers/xmlschema",Riddl::Handlers::XMLSchema)
