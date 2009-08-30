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

        def add_description(des,desres,path,index)
          #{{{
          res = add_path(path)
          res.add_requests(des,desres,index)
          desres.find("des:resource").each do |desres|
            res.add_description(des,desres,desres.attributes['relative'] || "{}",index)
          end
          #}}}
        end

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

        def to_xml
          #{{{
          result = ""
          messages = {}
          names = []
          messages_result = ""
          to_xml_priv(result,messages,0)
          messages.each do |hash,mess|
            t = mess.content.dup
            name = mess.name
            name += '_' while names.include?(name)
            t.root.attributes['name'] = name
            messages_result << t.root.dump + "\n"
          end
          "<description #{Riddl::File::COMMON}>\n\n" +  messages_result.gsub(/^/,'  ') + "\n" + result + "\n</description>"
          #}}}
        end

        def to_xml_priv(result,messages,level)
          #{{{
          s = "  " * (level + 1)
          t = "  " * (level + 2)
          result << s + "<resource#{@path != '/' && @path != '' ? " relative=\"#{@path}\"" : ''}>\n"
          @composition.each do |k,v|
            v.each do |m|
              if %w{get post put delete}.include?(k)
                result << t + "<#{k} "
              else
                result << t + "<request method=\"#.upcase{k}\" "
              end  
              case m
                when RequestInOut
                  result << "in=\"#{m.in.name}\""
                  messages[m.in.hash] = m.in
                  unless m.out.nil?
                    result << " out=\"#{m.out.name}\""
                    messages[m.out.hash] = m.out
                  end  
                when RequestStarOut  
                  result << "in=\"*\""
                  unless m.out.nil?
                    result << " out=\"#{m.out.name}\""
                    messages[m.out.hash] = m.out
                  end  
                when RequestPass
                  result << "pass=\"#{m.pass.name}\""
                  messages[m.pass.hash] = m.pass
                when RequestTransformation
                  result << "transformation=\"#{m.trans.name}\""
                  messages[m.trans.hash] = m.trans
              end  
              result << "/>\n"
            end  
          end
          @resources.each do |k,v|
            v.to_xml_priv(result,messages,level+1)
          end
          ""
          result << s + "</resource>\n"
          #}}}
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

        def compose!
          #{{{
          @requests.each do |k,v|
            case v.size
              when 0:
              when 1:
                @composition[k] = Composition.new(nil,v[0])
              else
                @composition[k] = compose(k,v)
            end
          end  
          #}}}
        end
        
        def compose(k,layers)
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
            ret = nil
            teh_last = r.last
            begin
              success = true
              if r.first.respond_to?(:in) && teh_last.respond_to?(:out)
                #1: responds first in + last out -> new InOut
                ret = RequestInOut.new_from_message(r.first.in,teh_last.out)
              elsif teh_last.respond_to?(:out)
                #2: responds last out only -> new StarOut
                ret = RequestStarOut.new_from_message(teh_last.out)
              elsif r.first.class == RequestTransformation && teh_last.class == RequestTransformation
                #3: first transform + last transform -> merge transformations
                ret = RequestTransformation.new_from_transformation(r.first.trans,teh_last.trans)
              elsif teh_last.class == RequestPass
                #4: last pass -> remove last until #1 or #2 or size == 1
                if r.size > 1
                  teh_last = r[-2]
                  success = false
                else 
                  ret = teh_last
                end  
              end
            end while !success
            Composition.new(r,ret)
          end
          #}}}
        end
        private :compose
        
        def clean!
          #{{{
          @resources = {}
          #}}}
        end

        def traverse_layers(container,path,layers,layer)
          #{{{
          return if layers.count <= layer
          current = path.last
          current_path = path.dup 

          # messages RequestInOut and RequestStarOut with no out are not processed
          return if ((current.class == RequestInOut || current.class == RequestStarOut) && current.out.nil?)

          if current.class == RequestInOut || 
            (current.class == RequestTransformation && !current.out.nil?) || 
             current.class == RequestStarOut
            # Find all where "in" matches
            layers[layer].find_all{ |l| (l.class == RequestInOut && l.in.traverse?(current.out) && !l.used?) }.each do |r|
              path << r
              path.last.used = true
              traverse_layers(container,path,layers,layer+1)
              return
            end
            # Find all in=* matches, they are all potential matches, even when used
            layers[layer].find_all{ |l| l.class == RequestPass || l.class == RequestStarOut || l.class == RequestTransformation }.each do |r|
              num = add_to_path_and_split(container,path,layers,layer,num||0,current_path,r)
            end
            return
          end  

          if (current.class == RequestTransformation && current.out.nil?) ||
              current.class == RequestPass
            # all unused RequestInOut and all others (even if used)
            layers[layer].find_all{|l| (l.class == RequestInOut && !l.used?) || (l.class != RequestInOut) }.each do |r|
              num = add_to_path_and_split(container,path,layers,layer,num||0,current_path,r)
            end
          end  
        #}}}
        end
        private :traverse_layers

        def add_to_path_and_split(container,path,layers,layer,num,current_path,r)
          #{{{
          if num > 0
            path = current_path.dup
            container << path
          end  
          path << r
          path.last.used = true
          traverse_layers(container,path,layers,layer+1)
          num + 1
          #}}}
        end
        private :add_to_path_and_split

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

        attr_reader :resources,:path,:requests,:composition,:routes
      end

      Composition = Struct.new(:route,:result)
      #class Composition
      #  def initialize(route,result)
      #    @route = route
      #    @result 
      #  end
      #end
    end
  end
end
