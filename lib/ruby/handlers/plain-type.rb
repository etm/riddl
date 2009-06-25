module Riddl
  module Handlers
    class PlainType
      def self::handle(what,hinfo)
        if what.class == Riddl::Parameter::Tempfile
          w = what.read
          what.rewind
        else  
          w = what
        end  
        begin
          re = Regexp.new(hinfo)
        rescue  
          return false
        end
        w =~ re
      end
    end
  end  
end  

Riddl::Handlers::add("http://riddl.org/ns/handlers/plain-type",Riddl::Handlers::PlainType)
