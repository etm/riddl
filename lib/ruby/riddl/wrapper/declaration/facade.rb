module Riddl
  class Wrapper
    class Declaration < WrapperUtils

      class Facade
        attr_reader :resource

        def initialize
          @resource = Riddl::Wrapper::Description::Resource.new("/")
        end

        def description_xml(namespaces)
          #{{{
          namespaces = namespaces.delete_if do |k,n|
            k =~ /^xmlns\d+$/ || [Riddl::Wrapper::DESCRIPTION, Riddl::Wrapper::DECLARATION, Riddl::Wrapper::XINCLUDE].include?(n)
          end.map do |k,n|
            "xmlns:#{k}=\"#{n}\""
          end.join(' ')

          result = ""
          messages = {}
          names = []
          messages_result = ""
          description_result = ""
          description_xml_priv(result,messages,0)

          result = XML::Smart.string(result)
          messages.each do |hash,mess|
            t = mess.content.dup
            name = mess.name
            name += '_' while names.include?(name)
            result.find("//@*[.=#{hash}]").each { |e| e.value = name }
            names << name
            t.root.attributes['name'] = name
            messages_result << t.root.dump + "\n"
          end
          XML::Smart.string("<description #{Riddl::Wrapper::COMMON} #{namespaces}>\n\n" + description_result + messages_result.gsub(/^/,'  ') + "\n" + result.root.dump + "\n</description>").to_s
          #}}}
        end
        def description_xml_priv(result,messages,level,res=@resource)
          #{{{
          s = "  " * (level + 1)
          t = "  " * (level + 2)
          result << s + "<resource#{res.path != '/' && res.path != '{}' ? " relative=\"#{res.path}\"" : ''}#{res.recursive ? " recursive=\"true\"" : ''}>\n"
          result << res.description_xml_string(messages,t)
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
          fac.custom = fac.custom + res.custom
          res.composition.each do |method,s|
            fac.composition[method] ||= []
            fac.composition[method] += s
          end
          res.resources.each do |path,r|
            if !fac.resources.has_key?(path)
              fac.resources[path] = Riddl::Wrapper::Description::Resource.new(path,r.recursive)
            end
            merge_tiles(r,fac.resources[path])
          end
          #}}}
        end
      end

    end
  end
end
