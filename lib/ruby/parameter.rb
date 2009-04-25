module Riddl
  class Parameter
    attr_reader :name, :value
    def initialize(name,value)
      @name = name
      @value = value
    end
  end
  class ParameterIO
    attr_reader :name, :mimetype, :filename, :file
    def initialize(name,mimetype,filename=nil,file=nil)
      @name = name
      @mimetype = mimetype
      @filename = filename
      if @file && @file.class == IO
        @file = file
      else
        raise "ERROR not a file" unless file.nil?
      end
      @file = yield if block_given?
    end
  end
end
