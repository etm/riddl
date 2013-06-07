module Riddl
  class Wrapper
    class Declaration < WrapperUtils

      class Facade
        def initialize
          @resource = Riddl::Wrapper::Description::Resource.new("/")
        end

        def description_xml
          #{{{
          result = ""
          messages = {}
          names = []
          messages_result = ""
          description_result = ""
          description_xml_priv(result,messages,0)
          messages.each do |hash,mess|
            t = mess.content.dup
            name = mess.name
            name += '_' while names.include?(name)
            t.root.attributes['name'] = name
            messages_result << t.root.dump + "\n"
          end
          "<description #{Riddl::Wrapper::COMMON}>\n\n" + description_result + messages_result.gsub(/^/,'  ') + "\n" + result + "\n</description>"
          #}}}
        end
        def description_xml_priv(result,messages,level,res=@resource)
          #{{{
          s = "  " * (level + 1)
          t = "  " * (level + 2)
          result << s + "<resource#{res.path != '/' && res.path != '{}' ? " relative=\"#{res.path}\"" : ''}#{res.recursive ? " recursive=\"true\"" : ''}>\n"
          res.composition.each do |k,v|
            v.each do |m|
              m = m.result
              if %w{get post put delete}.include?(k)
                result << t + "<#{k} "
              elsif  k == :websocket
                result << t + "<#{k}"
              else
                result << t + "<request method=\"#{k}\" "
              end  
              case m
                when Riddl::Wrapper::Description::RequestInOut
                  messages[m.in.hash] ||= m.in
                  result << "in=\"#{messages[m.in.hash].name}\""
                  unless m.out.nil?
                    messages[m.out.hash] ||= m.out
                    result << " out=\"#{messages[m.out.hash].name}\""
                  end  
                when Riddl::Wrapper::Description::RequestStarOut
                  result << "in=\"*\""
                  unless m.out.nil?
                    messages[m.out.hash] ||= m.out
                    result << " out=\"#{messages[m.out.hash].name}\""
                  end  
                when Riddl::Wrapper::Description::RequestPass
                  messages[m.pass.hash] ||= m.pass
                  result << "pass=\"#{messages[m.pass.hash].name}\""
                when Riddl::Wrapper::Description::RequestTransformation
                  messages[m.trans.hash] ||= m.trans
                  result << "transformation=\"#{messages[m.trans.hash].name}\""
              end  
              result << "/>\n"
            end  
          end
          res.resources.each do |k,v|
            description_xml_priv(result,messages,level+1,v)
          end
          ""
          result << s + "</resource>\n"
          #}}}
        end
        private :description_xml_priv
      
        def merge_tiles(res,fac=@resource)
          #{{{
          res.composition.each do |method,s|
            fac.composition[method] ||= []
            fac.composition[method] += s
          end  
          res.resources.each do |path,r|
            unless fac.resources.has_key?(path)
              fac.resources[path] = Riddl::Wrapper::Description::Resource.new(path,r.recursive)
            end  
            merge_tiles(r,fac.resources[path])
          end
          #}}}
        end

        attr_reader :resource
      end

    end
  end
end
