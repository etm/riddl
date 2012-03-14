module Riddl
  module Handlers
    @@handlers = {}
    def self::add(name,what)
      @@handlers[name] = what
    end
    def self::handlers
      @@handlers
    end
    class Implementation
      def self::handle(content,arguments); end
    end
  end
end  
