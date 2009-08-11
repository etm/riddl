require ::File.dirname(__FILE__) + '/description'

module Riddl
  class File
    class Declaration
      class Resource
        def initialize(path=nil)
          #{{{
          @path = path
          @resources = {}
          @requests = {}
          @composition = {}
          #}}}
        end

        def compose!
          #{{{
          @requests.each do |k,v|
            case v.size
              when 0:
              when 1:
                @composition[k] = v[0]
              else
                @composition[k] = compose(v)
            end
          end  
          #}}}
        end

        def compose(layers)
          routes = []
          layers.each_with_index do |lay,index|
            lay.find_all{|l|l.class==RequestInOut}.each do |r|
              traverse_layers(container = [[r]],container[0],layers,index+1) unless r.used?
              routes += container unless container.nil?
            end
            lay.find_all{|l|l.class==RequestTransformation}.each do |r|
              traverse_layers(container = [[r]],container[0],layers,index+1) unless r.used?
              routes += container unless container.nil?
            end
            lay.find_all{|l|l.class==RequestStarOut}.each do |r|
              traverse_layers(container = [[r]],container[0],layers,index+1) unless r.used?
              routes += container unless container.nil?
            end
            lay.find_all{|l|l.class==RequestPass}.each do |r|
              traverse_layers(container = [[r]],container[0],layers,index+1) unless r.used?
              routes += container unless container.nil?
            end
          end
          routes.map do |r|
            if r.first.respond_to?(:in) && r.last.respond_to?(:out)
              #1: responds first in + last out -> new InOut
              RequestInOut.new_from_message(r.first.in,r.last.out)
            elsif r.last.respond_to?(:out) && !r.last.out.nil?
              #2: responds last out only -> new StarOut
              RequestStarOut.new_from_message(r.last.out)
            elsif r.first.class == RequestTransformation && r.last.class == RequestTransformation
              #3: first transform + last transform -> merge transformations
              RequestTransformation.new_from_transformation(r.first.trans,r.last.trans)
            elsif r.last.class == RequestPass
              #4: last pass -> remove last until #1 or #2 
              raise "TODO"
            end
          end 
        end
        def traverse_layers(container,path,layers,layer)
          return if layers.count <= layer
          current =  path.last
          if current.class == RequestInOut || 
            (current.class == RequestTransformation && !current.out.nil?) || 
             current.class == RequestStarOut
            layers[layer].find_all{|l| l.class == RequestInOut && l.in.traverse?(current.out) && !l.used? }.each do |r|
              path << r
              path.last.used = true
              traverse_layers(container,path,layers,layer+1)
              return
            end
          end  
          if (current.class == RequestTransformation && current.out.nil?) ||
              current.class == RequestPass
            num = 0
            tpath = path.dup
            layers[layer].find_all{|l| !l.used?}.each do |r|
              if num > 0
                path = tpath.dup
                container << path
              end  
              path << r
              path.last.used = true
              traverse_layers(container,path,layers,layer+1)
              num += 1
            end
            return if num > 0
          end  
        end
        private :compose, :traverse_layers

        def add(path)
          #{{{
          pres = self
          path.split('/').each do |p|
            next if p == ""
            unless pres.resources.has_key?(p)
              pres.resources[p] = Resource.new(p)
            end
            pres = pres.resources[p]
          end
          pres
          #}}}
        end

        def clean!; @resouces = {}; end

        # add requests helper methods
        #{{{
        def add_request_in_out(index,des,method,min,mout)
          @requests[method] ||= []
          @requests[method][index] ||= []
          @requests[method][index] << RequestInOut.new(des,min,mout)
        end
        def add_request_transform(index,des,method,mtrans)
          @requests[method] ||= []
          @requests[method][index] ||= []
          @requests[method][index] << RequestTransformation.new(des,mtrans)
        end
        def add_request_star_out(index,des,method,mout)
          @requests[method] ||= []
          @requests[method][index] ||= []
          @requests[method][index] << RequestStarOut.new(des,mout)
        end
        def add_request_pass(index,des,method)
          @requests[method] ||= []
          @requests[method][index] ||= []
          @requests[method][index] << RequestPass.new
        end
        attr_reader :resources,:path,:requests,:composition
        #}}}
      end

      class Facade
        #{{{
        def initialize
          @resource = Resource.new("/")
        end
        def add(path)
          if path.nil? || path == '/'
            @resource
          else
            @resource.add(path)
          end
        end

        def visualize_tree_and_layers
          visualize :layers
        end
        def visualize_tree_and_composition
          visualize :composition
        end
        def generate_description

        end
        def visualize(mode,res=@resource,what='')
          what += res.path
          puts what
          if mode == :layers
            res.requests.each do |k,v|
              puts "  #{k.upcase}:"
              v.each_with_index do |l,i|
                puts "    Layer #{i}:"
                l.each do |r|
                  puts "      #{r.class.name.gsub(/[^\:]+::/,'')}: #{r.visualize}"
                end
              end
            end
          end
          if mode == :composition
            res.composition.each do |k,v|
              puts "  #{k.upcase}:"
              v.each do |r|
                puts "      #{r.class.name.gsub(/[^\:]+::/,'')}: #{r.visualize}"
              end
            end
          end
          res.resources.each do |key,r|
            visualize(mode,r,what + (what == '/' ? ''  : '/'))
          end
        end

        def compose!(res=@resource)
          res.compose!
          res.resources.each do |key,r|
            self.compose!(r)
          end
        end
        #}}}
      end

      # Request* helper classes
      #{{{
      class RequestBase
        def used=(value)
          @used = value
        end
        def used?
          @used || false
        end
      end
      class RequestInOut < RequestBase
        def initialize(des,min,mout)
          if des.nil?
            @in = min
            @out = mout
          else
            @in = Riddl::File::Description::Message.new(des,min)
            @out = Riddl::File::Description::Message.new(des,mout)
          end
        end
        def self.new_from_message(min,mout)
          RequestInOut.new(nil,min,mout)
        end
        attr_reader :in, :out
        def visualize; "in #{@in.name.inspect} out #{@out.name.inspect}"; end
      end
      class RequestTransformation < RequestBase
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
      end
      class RequestStarOut < RequestBase
        def initialize(des,mout)
          if des.nil?
            @out = mout
          else
            @out = Riddl::File::Description::Message.new(des,mout)
          end  
        end
        def self.new_from_message(mout)
          RequestStarOut.new(nil,mout)
        end
        attr_reader :out
        def visualize; "out #{@out.name.inspect}"; end
      end
      class RequestPass < RequestBase
        def visualize; ""; end
      end
      #}}}

      def apply_to(res,des,desres,path,index)
        #{{{
        res = res.add(path)
        add_requests(res,des,desres,index)
        desres.find("des:resource").each do |desres|
          apply_to(res,des,desres,desres.attributes['relative'] || "{}",index)
        end
        #}}}
      end
      private :apply_to

      def add_requests(res,des,desres,index)
        #{{{
        desres.find("des:*[@in and not(@in='*')]").each do |m|
          method = m.attributes['method'] || m.name.name
          res.add_request_in_out(index,des,method,m.attributes['in'],m.attributes['out'])
        end
        desres.find("des:*[@pass and not(@pass='*')]").each do |m|
          method = m.attributes['method'] || m.name.name
          res.add_request_in_out(index,des,method,m.attributes['pass'],m.attributes['pass'])
        end
        desres.find("des:*[@transformation]").each do |m|
          method = m.attributes['method'] || m.name.name
          res.add_request_transform(index,des,method,m.attributes['transformation'])
        end
        desres.find("des:*[@in and @in='*']").each do |m|
          method = m.attributes['method'] || m.name.name
          res.add_request_star_out(index,des,method,m.attributes['out'])
        end
        desres.find("des:*[@pass and @pass='*']").each do |m|
          method = m.attributes['method'] || m.name.name
          res.add_request_pass(index,des,method)
        end
        #}}}
      end
      private :add_requests

      def description
        @fac.generate_description
      end

      def initialize(riddl)
        #{{{
        @fac = Facade.new
        ### Forward
        riddl.find("/dec:declaration/dec:facade/dec:tile").each do |tile|
          res = @fac.add(tile.attributes['path'] || '/')
          res.clean! # for overlapping tiles, each tile gets an empty path
          tile.find("dec:layer").each_with_index do |layer,index|
            apply_to = layer.find("dec:apply-to")
            lname = layer.attributes['name']
            des = riddl.find("/dec:declaration/dec:interface[@name=\"#{lname}\"]/des:description").first
            desres = des.find("des:resource").first
            if apply_to.empty?
              apply_to(res,des,desres,"/",index)
            else
              apply_to.each do |at|
                apply_to(res,des,desres,at.to_s,index)
              end
            end
          end
        end
        @fac.compose!
        #}}}
      end
    end
  end
end
