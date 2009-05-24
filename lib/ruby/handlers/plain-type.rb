module Riddl
  module Handlers
    class PlainType
      def self::handle(what,hinfo)
        begin
          re = Regexp.new(hinfo)
        rescue  
          return false
        end
        what =~ re
      end
    end
  end  
end  

Riddl::Handlers::add("http://riddl.org/ns/handlers/plain-type",Riddl::Handlers::PlainType)
