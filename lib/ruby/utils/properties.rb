module Riddl
  module Utils
    module Properties

      VERSION_MAJOR = 1
      VERSION_MINOR = 0
      PROPERTIES_SCHEMA_XSL_RNG = "#{File.dirname(__FILE__)}/../ns/common-patterns/properties/#{VERSION_MAJOR}.#{VERSION_MINOR}/properties.schema.xsl"

      def extract_values(file,schema,property,minor=nil)
        XML::Smart::open(file) do |pdoc|
          pdoc.namespaces = { 'p' => 'http://riddl.org/ns/common-patterns/properties/1.0' }
          add = decision = nil
          if minor.nil?
            add = ''
            decision = map_or_value(schema,property)
          else
            add = "/*[name()=\"#{minor}\"]"
            decision = :value
          end  

          case decision
            when :map
              res = pdoc.find("/p:properties/*[name()=\"#{property}\"]#{add}")
              if res.any?
                prop = XML::Smart::string("<values xmlns=\"http://riddl.org/ns/common-patterns/properties/1.0\"/>")
                prop.root.add(res.first.find("*"))
              else
                prop = XML::Smart::string("<not-existing xmlns=\"http://riddl.org/ns/common-patterns/properties/1.0\"/>")
              end
              return Riddl::Parameter::Complex.new("value","text/xml",prop.to_s)
            when :value
              res = pdoc.find("string(/p:properties/*[name()=\"#{property}\"]#{add})")
              return Riddl::Parameter::Simple.new("value",res.to_s)
            when :content  
              res = pdoc.find("/p:properties/*[name()=\"#{property}\"]#{add}")
              if res.any?
                c = res.first.children
                if c.length == 1 && c.first.class == XML::Smart::Dom::Element
                  prop = c.first.dump
                else
                  prop = XML::Smart::string("<value xmlns=\"http://riddl.org/ns/common-patterns/properties/1.0\"/>")
                  prop.root.add c
                  prop = prop.to_s
                end  
              else
                prop = XML::Smart::string("<not-existing xmlns=\"http://riddl.org/ns/common-patterns/properties/1.0\"/>").to_s
              end
              return Riddl::Parameter::Complex.new("value","text/xml",prop)
          end
        end  
        nil
      end    
      private :extract_values

      def map_or_value(schema,property)
        XML::Smart::open(schema) do |doc|
          doc.namespaces = { 'p' => 'http://riddl.org/ns/common-patterns/properties/1.0' }
          exis = doc.find("/p:properties/*[name()='#{property}']|/p:properties/p:optional/*[name()='#{property}']")
          if exis.any?
            return exis.first.attributes['type'].to_sym
          else
            return nil
          end
        end
      end
      private :map_or_value
    end
  end  
end  
