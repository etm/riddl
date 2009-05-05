module Riddl
  module Parameter
    class Simple
      attr_reader :name, :value, :type
      def initialize(name,value,type=:body)
        @name = name
        @value = value
        @type = (type == :query ? :query : :body)
      end
    end
    class Complex
      attr_reader :name, :mimetype, :filename, :value, :type, :additional
      def initialize(name,mimetype,filename=nil,file=nil,additional=[])
        @name = name
        @mimetype = mimetype
        @filename = filename
        @type = :body
        @additional = additional
        if file && file.class == IO
          @value = file
        else
          raise "ERROR not a file" unless file.nil?
        end
        @value = yield if block_given?
      end
    end
  end  
end
