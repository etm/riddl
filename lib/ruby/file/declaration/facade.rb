module Riddl
  class File
    class Declaration

      class Facade
        #{{{
        def initialize
          @resource = Riddl::File::Description::Resource.new("/")
        end

        def generate_description_xml
          @resource.to_xml
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
              m = m.result
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

        attr_reader :resource
        #}}}
      end

    end
  end
end
