module Riddl
  module Handlers
    class RelaxNG < Riddl::Handlers::Implementation
      def self::handle(what,hinfo)
        w = if what.class == Riddl::Parameter::Tempfile || what.class == File
          XML::Smart.open_unprotected(what)
        else  
          XML::Smart.string(what)
        end  
        rng = XML::Smart.string("<payload>" + hinfo + "</payload>")
        rng.register_namespace 'r', 'http://relaxng.org/ns/structure/1.0'
        w.validate_against(rng.find("//r:grammar|//r:element").first.to_doc) rescue false
      end
    end
  end  
end  

Riddl::Handlers::add("http://riddl.org/ns/handlers/relaxng",Riddl::Handlers::RelaxNG)
