module Riddl
  module Roles
    @@roles = {}
    def self::add(name,what)
      @@roles[name] = what
    end
    def self::roles
      @@roles
    end
    class Implementation
      def self::before(method,parameters,headers,options); end
      def self::after(method,code,response,headers,options); end
    end
  end
end  
