module Riddl
  class Wrapper
    class Description

      class RequestBase
        #{{{
        def used=(value)
          @used = value
        end
        def used?
          @used || false
        end
        attr_reader :interface
        #}}}
      end

      class RequestInOut < RequestBase
        #{{{
        def initialize(des,min,mout,interface)
          @interface = interface
          if des.nil?
            @in = min
            @out = mout
          else
            @in = Riddl::Wrapper::Description::Message.new(des,min)
            @out = mout.nil? ? nil : Riddl::Wrapper::Description::Message.new(des,mout)
          end
        end
        def self.new_from_message(min,mout)
          RequestInOut.new(nil,min,mout,nil)
        end
        def hash
          @in.hash + (@out.nil? ? 0 : @out.hash)
        end
        attr_reader :in, :out
        def visualize; "in #{@in.name.inspect} out #{@out.nil? ? "NIL" : @out.name.inspect}"; end
        #}}}
      end

      class RequestTransformation < RequestBase
        #{{{
        def initialize(des,mtrans,interface)
          @interface = interface
          if des.nil?
            @trans = mtrans
          else  
            @trans = Riddl::Wrapper::Description::Transformation.new(des,mtrans)
          end  
          @out = nil
        end
        def self.new_from_transformation(mtrans1,mtrans2)
          tmp = XML::Smart::string("<transformation/>")
          tmp.root.add mtrans1.content.root.children
          tmp.root.add mtrans2.content.root.children
          RequestTransformation.new(nil,Riddl::Wrapper::Description::Transformation.new_from_xml("#{mtrans2.name}_#{mtrans2.name}_merged",tmp),nil)
        end
        def transform(min)
          tmp = self.dup
          if min.class == RequestInOut && !min.out.nil?
            tmp.out = min.out.transform(@trans)
          end
          tmp
        end
        attr_reader :trans
        attr_accessor :out
        def hash
          @trans.hash + (@out.nil? ? 0 : @out.hash)
        end
        def visualize; "transformation #{@trans.name.inspect}"; end
        #}}}
      end

      class RequestStarOut < RequestBase
        #{{{
        def initialize(des,mout,interface)
          @interface = interface
          if des.nil?
            @out = mout
          else
            @out = mout.nil? ? nil : Riddl::Wrapper::Description::Message.new(des,mout)
          end  
        end
        def self.new_from_message(mout)
          RequestStarOut.new(nil,mout,nil)
        end
        attr_reader :out
        def hash
          @out.nil? ? 0 : @out.hash
        end
        def visualize; "out #{@out.nil? ? "NIL" : @out.name.inspect}"; end
        #}}}
      end

      class RequestPass < RequestBase
        #{{{
        def initialize(interface)
          @interface = interface
        end  
        def visualize; ""; end
        def hash
          0
        end
        #}}}
      end
      
    end
  end
end
