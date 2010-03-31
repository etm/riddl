module Riddl
  module Utils
    module Properties

      VERSION_MAJOR = 1
      VERSION_MINOR = 0
      PROPERTIES_SCHEMA_XSL_RNG = "#{File.dirname(__FILE__)}/../ns/common-patterns/properties/#{VERSION_MAJOR}.#{VERSION_MINOR}/properties.schema.xsl"

      def self::implementation(properties,schema,strans,handler,level,details=:production)
        unless handler.class == Class && handler.superclass == Riddl::Utils::Properties::HandlerBase
          raise "handler not a subclass of HandlerBase"
        end
        lambda {
          run     Riddl::Utils::Properties::All,       properties,                 handler        if get
          run     Riddl::Utils::Properties::Query,     properties,                 handler        if get    'query'
          on resource 'schema' do
            run   Riddl::Utils::Properties::Schema,    properties, schema, strans                 if get
            on resource 'rng' do
              run Riddl::Utils::Properties::RngSchema, properties, schema, strans                 if get
            end  
          end
          on resource 'values' do
            run   Riddl::Utils::Properties::Keys,      properties, schema,         handler        if get
            run   Riddl::Utils::Properties::AddPair,   properties, schema, strans, handler, level if post   'key-value-pair'
            on resource do
              run Riddl::Utils::Properties::AddPair,   properties, schema, strans, handler, level if post   'key-value-pair'
              run Riddl::Utils::Properties::Values,    properties, schema,         handler, level if get
              run Riddl::Utils::Properties::Delete,    properties, schema, strans, handler, level if delete
              run Riddl::Utils::Properties::Put,       properties, schema, strans, handler, level if put    'value'
            end
          end  
        }
      end  

      def self::schema(fschema)
        fschema  = fschema.gsub(/^\/+/,'/')
        unless File.exists?(fschema)
          raise "schema file not found"
        end
        schema      = XML::Smart::open(fschema)
        schema.namespaces = { 'p' => 'http://riddl.org/ns/common-patterns/properties/1.0' }
        if !File::exists?(Riddl::Utils::Properties::PROPERTIES_SCHEMA_XSL_RNG)
          raise "properties schema transformation file not found"
        end  
        strans = schema.transform_with(XML::Smart::open(Riddl::Utils::Properties::PROPERTIES_SCHEMA_XSL_RNG))
        [schema,strans]
      end
      
      def self::file(fproperties)
        properties  = fproperties.gsub(/^\/+/,'/')
        unless File.exists?(properties)
          raise "properties file not found"
        end
        properties
      end

      def self::modifiable?(schema,property)
        schema.find("boolean(/p:properties/p:#{property}[@modifiable='true'])")
      end
      def self::valid_state?(schema,property,current,new)
        schema.find("boolean(/p:properties/p:#{property}/p:#{current}/p:#{new}[@putable='true'])")
      end
      def self::is_state?(schema,property)
        schema.find("boolean(/p:properties/p:#{property}[@type='state'])")
      end

      class HandlerBase
        def initialize(properties,property)
          @properties = properties 
          @property = property
        end
        def create; end
        def read;   end
        def update; end
        def delete; end
      end

      class All < Riddl::Implementation #{{{
        def response
          properties = @a[0]
          handler    = @a[1]
          handler.new(properties,nil).read
          return Riddl::Parameter::Complex.new("document","text/xml",File::open(properties))
        end
      end #}}}

      class Keys < Riddl::Implementation #{{{
        def response
          properties = @a[0]
          schema     = @a[1]
          handler    = @a[2]
          handler.new(properties,nil).read

          ret = XML::Smart.string("<keys xmlns=\"http://riddl.org/ns/common-patterns/properties/1.0\"/>")
          schema.find("/p:properties/*[name()!='optional']|/p:properties/p:optional/*").each do |r|
            ret.root.add("key",r.name.to_s)
          end
          return Riddl::Parameter::Complex.new("keys","text/xml",ret.to_s)
        end
      end #}}} 

      class Query < Riddl::Implementation #{{{
        def response
          properties = @a[0]
          handler    = @a[1]
          handler.new(properties,nil).read

          xml = File::read(properties).gsub(/properties xmlns="[^"]+"|properties xmlns='[^']+'/,'properties')
          e = XML::Smart::string(xml).root.find(@p[0].value)
          prop = XML::Smart::string("<value xmlns=\"http://riddl.org/ns/common-patterns/properties/1.0\"/>")
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
      end #}}}

      class RngSchema < Riddl::Implementation #{{{
        def response
          strans = @a[2]
          Riddl::Parameter::Complex.new("document-schema","text/xml",strans)
        end
      end #}}}

      class Schema < Riddl::Implementation #{{{
        def response
          schema = @a[1]
          return Riddl::Parameter::Complex.new("document-schema","text/xml",schema.to_s)
        end
      end #}}}

      class Values < Riddl::Implementation #{{{
        def response
          properties = @a[0]
          schema     = @a[1]
          handler    = @a[2]
          level      = @a[3]
          relpath    = @r[level..-1]
          handler.new(properties,relpath[1]).read

          p relpath
          if ret = extract_values(properties,schema,relpath[1],relpath[2])
            ret
          else
            @status = 404
          end
        end
        
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
              when :value, :state
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
          exis = schema.find("/p:properties/*[name()='#{property}']|/p:properties/p:optional/*[name()='#{property}']")
          if exis.any?
            return exis.first.attributes['type'].to_sym
          else
            return nil
          end
        end
        private :map_or_value
      end #}}}
      
      # Modifiable
      class AddPair < Riddl::Implementation #{{{
        def response
          properties = @a[0]
          schema     = @a[1]
          strans     = @a[2]
          handler    = @a[3]
          level      = @a[4]
          relpath    = @r[level..-1]

          key      = @p.detect{|p| p.name == 'key'}.value
          value    = @p.detect{|p| p.name == 'value'}.value
          property = relpath[1]
            
          unless Riddl::Utils::Properties::modifiable?(schema,property.nil? ? key : property)
            @status = 500
            return # change properties.schema
          end

          newstuff = XML::Smart.string("<#{key} xmlns=\"http://riddl.org/ns/common-patterns/properties/1.0\">#{value}</#{key}>")
          XML::Smart::open(properties) do |doc|
            doc.namespaces = { 'p' => 'http://riddl.org/ns/common-patterns/properties/1.0' }

            if property.nil?
              if doc.root.find("p:#{key}").any?
                @status = 500
                return # don't misuse post
              end
              doc.root.add newstuff.root
              if !doc.validate_against(XML::Smart::string(strans))
                @status = 400
                return # bad request
              end
            else
              node = doc.root.find("p:#{property}")
              if node.any?
                if node.first.find("p:#{key}").any?
                  @status = 500
                  return # don't misuse post
                end
              else
                @status = 404
                return # this property does not exist
              end
            end
          end

          # everything is fine, now do it
          XML::Smart::modify(properties) do |doc|
            doc.namespaces = { 'p' => 'http://riddl.org/ns/common-patterns/properties/1.0' }
            node = property.nil? ? doc.root : doc.find("/p:properties/p:#{property}").first
            node.add newstuff.root
          end

          handler.new(properties,property).create
          return Riddl::Parameter::Simple.new("key",key)
        end
      end #}}}

      class Delete < Riddl::Implementation #{{{
        def response
          properties = @a[0]
          schema     = @a[1]
          strans     = @a[2]
          handler    = @a[3]
          level      = @a[4]
          relpath    = @r[level..-1]

          key      = relpath[1]
          property = relpath[2]

          unless Riddl::Utils::Properties::modifiable?(schema,key)
            @status = 500
            return # change properties.schema
          end

          path = "p:#{key}" + (property.nil? ? '' : "/p:#{property}")

          XML::Smart::open(properties) do |doc|
            doc.namespaces = { 'p' => 'http://riddl.org/ns/common-patterns/properties/1.0' }
            nodes = doc.root.find(path)
            if nodes.empty?
              @status = 404
              return # this property does not exist
            end
            nodes.delete_all!
            if !doc.validate_against(XML::Smart::string(strans))
              @status = 400
              return # bad request
            end
          end

          XML::Smart::modify(properties) do |doc|
            doc.namespaces = { 'p' => 'http://riddl.org/ns/common-patterns/properties/1.0' }
            doc.root.find(path).delete_all!
          end

          handler.new(properties,key).delete
          return
        end
      end #}}} 

      class Put < Riddl::Implementation #{{{
        def response
          properties = @a[0]
          schema     = @a[1]
          strans     = @a[2]
          handler    = @a[3]
          level      = @a[4]
          relpath    = @r[level..-1]

          key      = relpath[1]
          value    = @p.detect{|p| p.name == 'value'}.value
          property = relpath[2]

          unless Riddl::Utils::Properties::modifiable?(schema,key)
            @status = 500
            return # change properties.schema
          end

          path = "p:#{key}" + (property.nil? ? '' : "/p:#{property}")
          pname = property.nil? ? key : property

          newstuff = XML::Smart.string("<#{pname} xmlns='http://riddl.org/ns/common-patterns/properties/1.0'>#{value}</#{pname}>")
          XML::Smart::open(properties) do |doc|
            doc.namespaces = { 'p' => 'http://riddl.org/ns/common-patterns/properties/1.0' }
            nodes = doc.root.find(path)
            if nodes.empty?
              @status = 404
              return # this property does not exist
            end
            if Riddl::Utils::Properties::is_state?(schema,key)
              unless Riddl::Utils::Properties::valid_state?(schema,key,nodes.first.to_s,value)
                @status = 404
                return # not a valid state from here on
              end
            end  
            parent = nodes.first.parent
            nodes.delete_all!
            parent.add(newstuff.root)
            if !doc.validate_against(XML::Smart::string(strans))
              @status = 400
              return # bad request
            end
          end

          XML::Smart::modify(properties) do |doc|
            doc.namespaces = { 'p' => 'http://riddl.org/ns/common-patterns/properties/1.0' }
            nodes = doc.root.find(path)
            parent = nodes.first.parent
            doc.root.find(path).delete_all!
            parent.add(newstuff.root)
          end
          
          handler.new(properties,key).update
          return
        end
      end #}}}

    end
  end
end
