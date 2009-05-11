module Riddl
  class Header
    attr_reader :name, :value
    def initialize(name,value,type=:body)
      @name = name
      @value = value
    end
  end
end  
