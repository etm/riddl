module Riddl
  class Wrapper
    class Description < WrapperUtils

      class Resource
        def initialize(path=nil,recursive=false)
          #{{{
          @path = path
          @role = nil
          @resources = {}
          @access_methods = {}
          @composition = {}
          @recursive = recursive
          @custom = []
          #}}}
        end

        def add_access_methods(des,desres,index,interface)
          #{{{
          desres.find("des:*[not(name()='resource') and not(name()='websocket') and not(name()='sse') and @in and not(@in='*')]").each do |m|
            method = m.attributes['method'] || m.qname.name
            add_request_in_out(index,interface,des,method,m.attributes['in'],m.attributes['out'],m.find('*|text()'))
          end
          desres.find("des:*[not(name()='resource') and not(name()='websocket') and not(name()='sse') and @pass and not(@pass='*')]").each do |m|
            method = m.attributes['method'] || m.qname.name
            add_request_in_out(index,interface,des,method,m.attributes['pass'],m.attributes['pass'],m.find('*|text()'))
          end
          desres.find("des:*[not(name()='resource') and not(name()='websocket') and not(name()='sse') and @transformation]").each do |m|
            method = m.attributes['method'] || m.qname.name
            add_request_transform(index,interface,des,method,m.attributes['transformation'],m.find('*|text()'))
          end
          desres.find("des:*[not(name()='resource') and not(name()='websocket') and not(name()='sse') and @in and @in='*']").each do |m|
            method = m.attributes['method'] || m.qname.name
            add_request_star_out(index,interface,des,method,m.attributes['out'],m.find('*|text()'))
          end
          desres.find("des:*[not(name()='resource') and not(name()='websocket') and not(name()='sse') and not(@in) and not(@pass)]").each do |m|
            method = m.attributes['method'] || m.qname.name
            add_request_star_out(index,interface,des,method,m.attributes['out'],m.find('*|text()'))
          end
          desres.find("des:*[not(name()='resource') and not(name()='websocket') and not(name()='sse') and @pass and @pass='*']").each do |m|
            method = m.attributes['method'] || m.qname.name
            add_request_pass(index,interface,method,m.find('*|text()'))
          end
          desres.find("des:*[name()='websocket']").each do |m|
            add_websocket(index,interface,m.find('*|text()'))
          end
          desres.find("des:*[name()='sse']").each do |m|
            add_sse(index,interface,m.find('*|text()'))
          end
          @role = desres.find("string(@role)")
          @role = nil if @role.strip == ''
          #}}}
        end

        def add_custom(desres)
          #{{{
          @custom += desres.find("*[not(self::des:*)]").to_a
          #}}}
        end

        # TODO add websockets
        # TODO add SSE

        def remove_access_methods(des,filter,index)
          #{{{
          freq = if filter['in'] && filter['in'] != '*'
            t = [RequestInOut,Riddl::Wrapper::Description::Message.new(des,filter['in'])]
            t << (filter['out'] ? Riddl::Wrapper::Description::Message.new(des,filter['out']) : nil)
          elsif filter['pass'] && filter['pass'] != '*'
            [RequestInOut,Riddl::Wrapper::Description::Message.new(des,filter['pass']),Riddl::Wrapper::Description::Message.new(des,filter['pass'])]
          elsif filter['in'] && filter['in'] == '*'
            t = [RequestStarOut]
            t << (filter['out'] ? Riddl::Wrapper::Description::Message.new(des,filter['out']) : nil)
          elsif filter['transformation']
            [RequestTransformation,Riddl::Wrapper::Description::Transformation.new(des,filter['transformation'])]
          elsif filter['pass'] && filter['pass'] == '*'
            [RequestPass]
          elsif filter['method'] == 'sse'
            [SSE]
          end
          raise BlockError, "blocking #{filter.inspect} not possible" if freq.nil?

          if reqs = @access_methods[filter['method']]
            reqs = reqs[index]
            reqs.delete_if do |req|
              if req.class == freq[0]
                if req.class == RequestInOut
                  # TODO These hash comparisons are maybe too trivial, as we want to catch name="*" parameters
                  if freq[1] && freq[1].hash == req.in.hash && freq[2] && req.out && freq[2].hash == req.out.hash
                    true
                  elsif freq[1] && freq[1].hash == req.in.hash && !freq[2]
                    true
                  end
                elsif req.class == RequestStarOut
                  true if freq[1] && req.out && freq[1].hash == req.out.hash
                elsif req.class == RequestTransformation
                  true if freq[1] && freq[1].hash == req.trans.hash
                elsif req.class == RequestPass
                  true
                elsif req.class == SSE
                  true
                end
              end
            end
          end
          if @access_methods[filter['method']][index].empty?
            @access_methods[filter['method']].delete_at(index)
          end
          @access_methods[filter['method']].compact!
          if @access_methods[filter['method']].length == 0
            @access_methods.delete(filter['method'])
          end
          #}}}
        end

        def compose!
          #{{{
          @access_methods.each do |k,v|
            ### remove all emtpy layers
            v.map!{|e| (e.nil? || e.empty?) ? nil: e }
            v.compact!
            case v.size
              when 0
              when 1
                @composition[k] = compose_plain(v[0])
              else
                @composition[k] = compose_layers(k,v)
            end
          end
          #}}}
        end

        def compose_layers(k,layers)
          #{{{
          routes = []
          layers[0].find_all{|l|l.class==RequestInOut}.each do |r|
            traverse_layers(container = [[r]],container[0],layers,1) unless r.used?
            routes += container unless container.nil?
          end
          layers[0].find_all{|l|l.class==RequestTransformation}.each do |r|
            traverse_layers(container = [[r]],container[0],layers,1) unless r.used?
            routes += container unless container.nil?
          end
          layers[0].find_all{|l|l.class==RequestStarOut}.each do |r|
            traverse_layers(container = [[r]],container[0],layers,1) unless r.used?
            routes += container unless container.nil?
          end
          layers[0].find_all{|l|l.class==RequestPass}.each do |r|
            traverse_layers(container = [[r]],container[0],layers,1) unless r.used?
            routes += container unless container.nil?
          end
          routes.map do |r|
            ret = nil
            teh_last = r.last
            teh_first = r.first
            lcount = r.size
            fcount = 0
            begin
              success = true
              if teh_first.respond_to?(:in) && teh_last.respond_to?(:out)
                #1: responds first in + last out -> new InOut
                ret = RequestInOut.new_from_message(teh_first.in,teh_last.out,teh_first.custom)
              elsif teh_first.class == RequestTransformation && teh_last.class == RequestTransformation && teh_last.out.nil?
                #2: first transform + last transform -> merge transformations
                ret = RequestTransformation.new_from_transformation(teh_first.trans,teh_last.trans,teh_first.custom)
              elsif teh_first.class == RequestPass
                if r.size > (fcount + 1)
                  teh_first = r[fcount+=1]
                  success = false
                else
                  ret = teh_last
                end
              elsif teh_last.respond_to?(:out)
                #3: responds last out only -> new StarOut
                ret = RequestStarOut.new_from_message(teh_last.out,teh_last.custom)
              elsif teh_last.class == RequestPass
                #4: last pass -> remove last until #1 or #2 or #3 or size == 1
                if lcount - 1 > 0
                  teh_last = r[lcount -= 1]
                  success = false
                else
                  ret = teh_first
                end
              end
            end while !success
            Composition.new(r,ret)
          end
          #}}}
        end
        private :compose_layers

        def compose_plain(access_method)
          #{{{
          access_method.map do |ret|
            Composition.new(nil,ret)
          end
          #}}}
        end
        private :compose_plain

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
            # Find all possible transformations and apply them
            layers[layer].find_all{ |l| l.class == RequestTransformation }.each_with_index do |r,num|
              if num > 0
                path = current_path.dup
                container << path
              end
              path << r.transform(current)
              r.used = true
              traverse_layers(container,path,layers,layer+1)
            end
            # Find all in=* matches, they are all potential matches, even when used
            layers[layer].find_all{ |l| l.class == RequestPass || l.class == RequestStarOut }.each_with_index do |r,num|
              add_to_path_and_split(container,path,layers,layer,num,current_path,r)
            end
            return
          end

          if (current.class == RequestTransformation && current.out.nil?) ||
              current.class == RequestPass
            # all unused RequestInOut and all others (even if used)
            layers[layer].find_all{|l| (l.class == RequestInOut && !l.used?) || (l.class != RequestInOut) }.each_with_index do |r,num|
              add_to_path_and_split(container,path,layers,layer,num,current_path,r)
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
          #}}}
        end
        private :add_to_path_and_split

        def description_xml_string_analyse(messages,t,k,m)
 #{{{
          result = ''
          if %w{get post put patch delete websocket sse}.include?(k)
            result << t + "<#{k} "
          else
            result << t + "<request method=\"#{k}\" "
          end
          case m
            when Riddl::Wrapper::Description::RequestInOut
              messages[m.in.hash] ||= m.in
              result << "in=\"#{m.in.hash}\""
              unless m.out.nil?
                messages[m.out.hash] ||= m.out
                result << " out=\"#{m.out.hash}\""
              end
            when Riddl::Wrapper::Description::RequestStarOut
              result << "in=\"*\""
              unless m.out.nil?
                messages[m.out.hash] ||= m.out
                result << " out=\"#{m.out.hash}\""
              end
            when Riddl::Wrapper::Description::RequestPass
              result << "pass=\"*\""
            when Riddl::Wrapper::Description::RequestTransformation
              messages[m.trans.hash] ||= m.trans
              result << "transformation=\"#{m.trans.hash}\""
          end
          if m.custom.length > 0
            result << ">\n"
            m.custom.each do |e|
              result << e.dump + "\n"
            end
            if %w{get post put patch delete websocket sse}.include?(k)
              result << t + "</#{k}>"
            else
              result << t + "</request>\n"
            end
          else
            result << "/>\n"
          end
          result
 #}}}
        end
        private :description_xml_string_analyse

        def description_xml_string(messages,t)
 #{{{
          result = ''
          @custom.each do |c|
            result << c.dump
          end

          if @composition.any?
            @composition.each do |k,v|
              v.each do |m|
                result << description_xml_string_analyse(messages,t,k,m.result)
              end
            end
          else
            @access_methods.each do |k,v|
              v.first.each do |m|
                result << description_xml_string_analyse(messages,t,k,m)
              end
            end
          end
          result
 #}}}
        end
        def description_xml_string_sub(messages,t)
 #{{{
          result = ''
          @resources.each do |k,r|
            tmp = r.custom.map{ |c| c.dump }.join
            result << t + "<resource"
            result << " relative=\"#{k}\"" unless k == "{}"
            result << (tmp == '' ? "/>\n" : ">\n" + tmp + t + "</resource>\n")
          end
          result
 #}}}
        end

        def description_xml(namespaces)
          #{{{
          namespaces = namespaces.delete_if do |k,n|
            k =~ /^xmlns\d+$/ || [Riddl::Wrapper::DESCRIPTION, Riddl::Wrapper::DECLARATION, Riddl::Wrapper::XINCLUDE].include?(n)
          end.map do |k,n|
            "xmlns:#{k}=\"#{n}\""
          end.join(' ')

          messages = {}
          messages_result = ''
          collect = description_xml_string(messages," " * 4) + description_xml_string_sub(messages," " * 4)
          collect = XML::Smart.string("<resource>\n" + collect + "  </resource>")

          names = []
          messages.each do |hash,mess|
            t = mess.content.dup
            name = mess.name
            name += '_' while names.include?(name)
            collect.find("//@*[.=#{hash}]").each { |e| e.value = name }
            names << name
            t.root.attributes['name'] = name
            messages_result << t.root.dump + "\n"
          end
          XML::Smart.string("<description #{Riddl::Wrapper::COMMON} #{namespaces}>\n\n" + messages_result.gsub(/^/,'  ') + "\n  " + collect.root.dump + "\n</description>").to_s
          #}}}
        end

        # private add requests helper methods
        #{{{
        def add_request_in_out(index,interface,des,method,min,mout,custom)
          @access_methods[method] ||= []
          @access_methods[method][index] ||= []
          @access_methods[method][index] << RequestInOut.new(des,min,mout,interface,custom)
        end
        private :add_request_in_out

        def add_request_transform(index,interface,des,method,mtrans,custom)
          @access_methods[method] ||= []
          @access_methods[method][index] ||= []
          @access_methods[method][index] << RequestTransformation.new(des,mtrans,interface,custom)
        end
        private :add_request_transform

        def add_request_star_out(index,interface,des,method,mout,custom)
          @access_methods[method] ||= []
          @access_methods[method][index] ||= []
          @access_methods[method][index] << RequestStarOut.new(des,mout,interface,custom)
        end
        private :add_request_star_out

        def add_request_pass(index,interface,method,custom)
          @access_methods[method] ||= []
          @access_methods[method][index] ||= []
          @access_methods[method][index] << RequestPass.new(interface,custom)
        end
        private :add_request_pass

        def add_websocket(index,interface,custom)
          @access_methods['websocket'] ||= []
          @access_methods['websocket'][index] ||= []
          @access_methods['websocket'][index] << WebSocket.new(interface,custom)
        end
        private :add_websocket

        def add_sse(index,interface,custom)
          @access_methods['sse'] ||= []
          @access_methods['sse'][index] ||= []
          @access_methods['sse'][index] << SSE.new(interface,custom)
        end
        private :add_sse
        #}}}

        attr_reader :resources,:path,:access_methods,:composition,:recursive,:role
        attr_accessor :custom
      end

      Composition = Struct.new(:route,:result)
    end
  end
end
