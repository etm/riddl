module Riddl
  module Utils
    class Properties < Riddl::Implementation

      def extract_values(file,schema,element,minor=nil)
        XML::Smart::open(schema) do |doc|
          doc.namespaces = { 'rng' => 'http://relaxng.org/ns/structure/1.0' }
          XML::Smart::open(file) do |pdoc|
            pdoc.namespaces = { 'p' => 'http://riddl.org/ns/common-patterns/properties/1.0' }
            exis = doc.find("/rng:element/rng:element[@name=\"#{element}\"]|/rng:element/rng:optional/rng:element[@name=\"#{element}\"]")
            if exis.any?
              add = minor.nil? ? '' : "/*[name()=\"#{minor}\"]"
              if exis.first.find("rng:externalRef").any? && minor.nil?
                res = pdoc.find("/p:properties/*[name()=\"#{element}\"]#{add}|/p:properties/p:optional/*[name()=\"#{element}\"]#{add}")
                if res.any?
                  prop = XML::Smart::string("<values xmlns=\"http://riddl.org/ns/common-patterns/properties/1.0\"/>")
                  prop.root.add(res.first.find("*"))
                else
                  prop = XML::Smart::string("<not-existing xmlns=\"http://riddl.org/ns/common-patterns/properties/1.0\"/>")
                end
                return Riddl::Parameter::Complex.new("value","text/xml",prop.to_s)
              else  
                res = pdoc.find("string(/p:properties/*[name()=\"#{element}\"]#{add}|/p:properties/p:optional/*[name()=\"#{element}\"]#{add})")
                return Riddl::Parameter::Simple.new("value",res.to_s)
              end  
            end
          end  
        end
        nil
      end    
      private :extract_values

      def response
        if @a.length != 2 && !File.exists?(@a[0]) && ! File.exists?(@a[1])
          raise "properties or schema file not found"
        end  

        if @m == "get" && @r == ["schema"]
          return Riddl::Parameter::Complex.new("document-schema","text/xml",File::open(@a[1]))
        end  

        if @m == "get" && @r.empty? && @p.empty?
          return Riddl::Parameter::Complex.new("document","text/xml",File::open(@a[0]))
        end  

        if @m == "get" && @r.empty? && @p[0].name == 'query'
          xml = File::read(@a[0]).gsub(/properties xmlns="[^"]+"|properties xmlns='[^']+'/,'properties')
          e = XML::Smart::string(xml).root.find(@p[0].value)
          prop = XML::Smart::string("<values xmlns=\"http://riddl.org/ns/common-patterns/properties/1.0\"/>")
          if e.class == XML::Smart::Dom::NodeSet
            if e.any?
              t = e.first
              if t.find("*").any?
                prop.root.add(t.children)
              else  
                prop.root.text = t.to_s
              end  
            else
              XML::Smart::string("<not-existing xmlns=\"http://riddl.org/ns/common-patterns/properties/1.0\"/>")
            end
          else
            prop.root.text = e.to_s
          end
          return Riddl::Parameter::Complex.new("document","text/xml",prop.to_s)
        end

        if @m == "get" && @r == ["values"]
          XML::Smart::open(@a[1]) do |doc|
            doc.namespaces = { 'rng' => 'http://relaxng.org/ns/structure/1.0' }
            ret = XML::Smart.string("<keys xmlns=\"http://riddl.org/ns/common-patterns/properties/1.0\"/>")
            doc.find("/rng:element/rng:element/@name|/rng:element/rng:optional/rng:element/@name").each do |r|
              ret.root.add("key",r.to_s)
            end
            return Riddl::Parameter::Complex.new("keys","text/xml",ret.to_s)
          end
        end

        if @m == "get" && @r.length == 2 && @r[0] == "values"
          ret = extract_values(@a[0],@a[1],@r[1])
          return ret unless ret.nil?
        end
        
        if @m == "get" && @r.length == 3 && @r[0] == "values"
          ret = extract_values(@a[0],@a[1],@r[1],@r[2])
          return ret unless ret.nil?
        end

        @status = '404'
      end  
    end
  end  
end  
