module Riddl
  class Wrapper
    class Declaration < WrapperUtils

      class Interface
        def initialize(top,base,sub)
          @top = top
          @base = base
          @sub = sub
        end

        def self.new_from_interface(interface,sub)
          Interface.new(interface.top,interface.base,sub)
        end

        attr_reader :top, :base, :sub
      end

    end
  end
end
