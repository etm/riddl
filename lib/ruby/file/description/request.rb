module Riddl
  class File
    class Description

      class RequestBase
        #{{{
        def used=(value)
          @used = value
        end
        def used?
          @used || false
        end
        #}}}
      end

      class RequestInOut < RequestBase
        #{{{
        def initialize(des,min,mout)
          if des.nil?
            @in = min
            @out = mout
          else
            @in = Riddl::File::Description::Message.new(des,min)
            @out = mout.nil? ? nil : Riddl::File::Description::Message.new(des,mout)
          end
        end
        def self.new_from_message(min,mout)
          RequestInOut.new(nil,min,mout)
        end
        attr_reader :in, :out
        def visualize; "in #{@in.name.inspect} out #{@out.nil? ? "NIL" : @out.name.inspect}"; end
        #}}}
      end

      class RequestTransformation < RequestBase
        #{{{
        def initialize(des,mtrans)
          if des.nil?
            @trans = mtrans
          else  
            @trans = Riddl::File::Description::Transformation.new(des,mtrans)
          end  
          @out = nil
        end
        def self.new_from_transformation(mtrans1,mtrans2)
          tmp = XML::Smart::string("<transformation/>")
          tmp.root.add mtrans1.content.root.children
          tmp.root.add mtrans2.content.root.children
          RequestTransformation.new(nil,Riddl::File::Description::Transformation.new_from_xml("#{mtrans1.name}_#{mtrans2.name}_merged",tmp))
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
        def visualize; "transformation #{@trans.name.inspect}"; end
        #}}}
      end

      class RequestStarOut < RequestBase
        #{{{
        def initialize(des,mout)
          if des.nil?
            @out = mout
          else
            @out = mout.nil? ? nil : Riddl::File::Description::Message.new(des,mout)
          end  
        end
        def self.new_from_message(mout)
          RequestStarOut.new(nil,mout)
        end
        attr_reader :out
        def visualize; "out #{@out.nil? ? "NIL" : @out.name.inspect}"; end
        #}}}
      end

      class RequestPass < RequestBase
        #{{{
        def visualize; ""; end
        #}}}
      end
      
    end
  end
end
