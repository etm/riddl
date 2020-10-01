module Riddl
  module Handlers
    class PlainType
      def self::handle(what,hinfo)
        if what.class == Riddl::Parameter::Tempfile
          w = what.read
        else
          w = what
        end
        begin
          hi = XML::Smart::string(hinfo)
          re = Regexp.new(hi.root.text)
        rescue
          return false
        end
        w =~ re
      end
    end
  end
end

Riddl::Handlers::add("http://riddl.org/ns/handlers/plain-type",Riddl::Handlers::PlainType)
