module Riddl
  module Utils
    module Properties

      def extract_values(file,schema,property,minor=nil)
        XML::Smart::open(file) do |pdoc|
          pdoc.namespaces = { 'p' => 'http://riddl.org/ns/common-patterns/properties/1.0' }
          add = minor.nil? ? '' : "/*[name()=\"#{minor}\"]"
          case map_or_value(schema,property,minor)
            when :map  
              res = pdoc.find("/p:properties/*[name()=\"#{property}\"]#{add}|/p:properties/p:optional/*[name()=\"#{property}\"]#{add}")
              if res.any?
                prop = XML::Smart::string("<values xmlns=\"http://riddl.org/ns/common-patterns/properties/1.0\"/>")
                prop.root.add(res.first.find("*"))
              else
                prop = XML::Smart::string("<not-existing xmlns=\"http://riddl.org/ns/common-patterns/properties/1.0\"/>")
              end
              return Riddl::Parameter::Complex.new("value","text/xml",prop.to_s)
            when :value
              res = pdoc.find("string(/p:properties/*[name()=\"#{property}\"]#{add}|/p:properties/p:optional/*[name()=\"#{property}\"]#{add})")
              return Riddl::Parameter::Simple.new("value",res.to_s)
          end
        end  
        nil
      end    
      private :extract_values

      def map_or_value(schema,property,minor=nil)
        XML::Smart::open(schema) do |doc|
          doc.namespaces = { 'rng' => 'http://relaxng.org/ns/structure/1.0' }
          exis = doc.find("/rng:element/rng:interleave/rng:element[@name=\"#{property}\"]|/rng:element/rng:interleave/rng:optional/rng:element[@name=\"#{property}\"]")
          
          if exis.any?
            return exis.first.find("rng:externalRef").any? && minor.nil? ? :map : :value
          else
            return nil
          end
        end
      end
      private :map_or_value
    end
  end  
end  
