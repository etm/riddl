module Riddl
  class Wrapper
    class Declaration < WrapperUtils

      class Interface
        def initialize(name,top,base,sub,des)
          @name = name
          @top  = top
          @base = base
          @sub  = sub
          @des  = des
        end

        def self.new_from_interface(interface,sub)
          Interface.new(interface.name,interface.top,interface.base,sub,interface.des)
        end

        def real_path(real)
          t = @top.sub(/^\/*/,'').split('/')
          real = real.sub(/^\/*/,'').split('/')
          real = real[t.length..-1]
          '/' + real.join('/')
        end

        def real_url(real,base)
          (@base == '' ? base : @base) + real_path(real)
        end

        attr_reader :top, :base, :sub, :name, :des
      end

    end
  end
end
