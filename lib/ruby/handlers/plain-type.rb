module Riddl
  module Handlers
    class PlainType
      def in(what,hinfo)
        begin
          re = Regexp.new(hinfo)
        rescue  
          return false
        end
        what =~ re
      end
      def out(what,hinfo)
        in(what,hinfo)
      end
    end
  end  
end  

Riddl::Handlers::handler("http://riddl.org/ns/handlers/plain-type",Riddl::Handlers::PlainType)
