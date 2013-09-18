require 'tempfile'

module Riddl
  module Parameter
    class Array < ::Array
      def value(index)
        tmp = find_all{|e| e.name == index}
        case tmp.length
          when 0; nil
          when 1; tmp[0].value
          else tmp
        end if tmp
      end
    end
    class Simple
      attr_accessor :name, :value, :type
      def initialize(name,value,type=:body)
        @name = name
        @value = value
        @type = (type == :query ? :query : :body)
      end
    end
    class Complex
      attr_reader :mimetype, :filename, :value, :type, :additional
      attr_accessor :name
      def initialize(name,mimetype,file=nil,filename=nil,additional=[])
        @name = name
        @mimetype = mimetype.gsub(/;.*/,'')
        @filename = filename
        @type = :body
        @additional = additional

        @value = block_given? ? yield : file
        unless (@value && (@value.class == String || (file.respond_to?(:read) && file.respond_to?(:rewind))))
          raise "ERROR input is not a stream or string"
        end
      end
      def reopen
        if @value.class == File || @value.class == Riddl::Parameter::Tempfile
          pname = @value.path
          @value.close
          @value = File.open(pname,'r')
        end  
      end
    end
    class Tempfile < ::Tempfile
      def _close
        @tmpfile.close if @tmpfile
        @data[1] = nil if @data
        @tmpfile = nil
      end
    end
  end  
end
