module Riddl
  module Parameter
    class Simple
      attr_reader :name, :value
      def initialize(name,value)
        @name = name
        @value = value
      end
    end
    class Complex
      attr_reader :name, :mimetype, :filename, :value
      def initialize(name,mimetype,filename=nil,file=nil)
        @name = name
        @mimetype = mimetype
        @filename = filename
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
