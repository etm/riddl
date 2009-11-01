require 'tempfile'

module Riddl
  module Parameter
    class Simple
      attr_reader :value, :type
      attr_accessor :name
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
