module Riddl
  class Wrapper
    class Declaration < WrapperUtils

      class Facade
        def initialize
          @resource = Riddl::Wrapper::Description::Resource.new("/")
        end

        def description_xml(get_description)
          #{{{
          result = ""
          messages = {}
          names = []
          messages_result = ""
          description_result = ""
          description_xml_priv(result,messages,0,get_description)
          messages.each do |hash,mess|
            t = mess.content.dup
            name = mess.name
            name += '_' while names.include?(name)
            t.root.attributes['name'] = name
            messages_result << t.root.dump + "\n"
          end
          if get_description
            description_result = <<-END
              <message name="riddl-description-response">
                <parameter name="riddl-description" mimetype="text/xml"/>
              </message>
              <message name="riddl-description-request">
                <parameter name="riddl-description" type="string"/>
              </message>

            END
            description_result.gsub!(/^            /,'')
          end
          "<description #{Riddl::Wrapper::COMMON}>\n\n" + description_result + messages_result.gsub(/^/,'  ') + "\n" + result + "\n</description>"
          #}}}
        end
        def description_xml_priv(result,messages,level,get_description,res=@resource)
          #{{{
          s = "  " * (level + 1)
          t = "  " * (level + 2)
          p res.path
          p res.recursive
          p "------"
          result << s + "<resource#{res.path != '/' && res.path != '{}' ? " relative=\"#{res.path}\"" : ''}#{res.recursive ? " recursive=\"true\"" : ''}>\n"
          if get_description
            result << t + "<get in='riddl-description-request' out='riddl-description-response'/>\n"
          end  
          res.composition.each do |k,v|
            v.each do |m|
              m = m.result
              if %w{get post put delete}.include?(k)
                result << t + "<#{k} "
              else
                result << t + "<request method=\"#.upcase{k}\" "
              end  
              case m
                when Riddl::Wrapper::Description::RequestInOut
                  result << "in=\"#{m.in.name}\""
                  messages[m.in.hash] = m.in
                  unless m.out.nil?
                    result << " out=\"#{m.out.name}\""
                    messages[m.out.hash] = m.out
                  end  
                when Riddl::Wrapper::Description::RequestStarOut
                  result << "in=\"*\""
                  unless m.out.nil?
                    result << " out=\"#{m.out.name}\""
                    messages[m.out.hash] = m.out
                  end  
                when Riddl::Wrapper::Description::RequestPass
                  result << "pass=\"#{m.pass.name}\""
                  messages[m.pass.hash] = m.pass
                when Riddl::Wrapper::Description::RequestTransformation
                  result << "transformation=\"#{m.trans.name}\""
                  messages[m.trans.hash] = m.trans
              end  
              result << "/>\n"
            end  
          end
          res.resources.each do |k,v|
            description_xml_priv(result,messages,level+1,false,v)
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
              fac.resources[path] = Riddl::Wrapper::Description::Resource.new(path)
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
