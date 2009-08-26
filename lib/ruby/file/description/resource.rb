module Riddl
  class File
    class Description

      class Resource
        def initialize(path=nil)
          #{{{
          @path = path
          @resources = {}
          @requests = {}
          @composition = {}
          #}}}
        end

        def add(des,desres,path,index)
          #{{{
          res = add_path(path)
          add_requests(des,desres,index)
          desres.find("des:resource").each do |desres|
            res.apply_to(des,desres,desres.attributes['relative'] || "{}",index)
          end
          #}}}
        end

        def to_xml
          "hallo"
        end

        def add_requests(des,desres,index)
          #{{{
          desres.find("des:*[@in and not(@in='*')]").each do |m|
            method = m.attributes['method'] || m.name.name
            add_request_in_out(index,des,method,m.attributes['in'],m.attributes['out'])
          end
          desres.find("des:*[@pass and not(@pass='*')]").each do |m|
            method = m.attributes['method'] || m.name.name
            add_request_in_out(index,des,method,m.attributes['pass'],m.attributes['pass'])
          end
          desres.find("des:*[@transformation]").each do |m|
            method = m.attributes['method'] || m.name.name
            add_request_transform(index,des,method,m.attributes['transformation'])
          end
          desres.find("des:*[@in and @in='*']").each do |m|
            method = m.attributes['method'] || m.name.name
            add_request_star_out(index,des,method,m.attributes['out'])
          end
          desres.find("des:*[@pass and @pass='*']").each do |m|
            method = m.attributes['method'] || m.name.name
            add_request_pass(index,des,method)
          end
          #}}}
        end
        private :add_requests

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
          #{{{
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
          #}}}
        end
        private :compose

        def traverse_layers(container,path,layers,layer)
          #{{{
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
        #}}}
        end
        private :traverse_layers

        def add_path(path)
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
        private :add_path

        def clean!; @resouces = {}; end

        # add requests helper methods
        #{{{
        def add_request_in_out(index,des,method,min,mout)
          @requests[method] ||= []
          @requests[method][index] ||= []
          @requests[method][index] << RequestInOut.new(des,min,mout)
        end
        private :add_request_in_out

        def add_request_transform(index,des,method,mtrans)
          @requests[method] ||= []
          @requests[method][index] ||= []
          @requests[method][index] << RequestTransformation.new(des,mtrans)
        end
        private :add_request_transform

        def add_request_star_out(index,des,method,mout)
          @requests[method] ||= []
          @requests[method][index] ||= []
          @requests[method][index] << RequestStarOut.new(des,mout)
        end
        private :add_request_star_out

        def add_request_pass(index,des,method)
          @requests[method] ||= []
          @requests[method][index] ||= []
          @requests[method][index] << RequestPass.new
        end
        private :add_request_pass
        #}}}

        attr_reader :resources,:path,:requests,:composition
      end

    end
  end
end
