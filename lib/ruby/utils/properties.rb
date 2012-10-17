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
        Proc.new {
          if get("*")
            run    Riddl::Utils::Properties::All,            properties,                 handler       
          end
          run(     Riddl::Utils::Properties::Query,          properties,                 handler       ) if get    'query'
          on resource 'schema' do
            run(   Riddl::Utils::Properties::Schema,         properties, schema, strans                ) if get
            on resource 'rng' do
              run( Riddl::Utils::Properties::RngSchema,      properties, schema, strans                ) if get
            end  
          end
          on resource 'values' do
            run(   Riddl::Utils::Properties::Properties,     properties, schema,         handler       ) if get
            run(   Riddl::Utils::Properties::AddProperty,    properties, schema, strans, handler, level) if post   'property'
            run(   Riddl::Utils::Properties::AddProperties,  properties, schema, strans, handler, level) if put    'properties'
            on resource do
              run( Riddl::Utils::Properties::GetContent,     properties, schema,         handler, level) if get
              run( Riddl::Utils::Properties::DelContent,     properties, schema, strans, handler, level) if delete
              run( Riddl::Utils::Properties::AddContent,     properties, schema, strans, handler, level) if post   'addcontent'
              run( Riddl::Utils::Properties::UpdContent,     properties, schema, strans, handler, level) if put    'updcontent'
              on resource do
                run( Riddl::Utils::Properties::GetContent,   properties, schema,         handler, level) if get
                run( Riddl::Utils::Properties::DelContent,   properties, schema, strans, handler, level) if delete
                run( Riddl::Utils::Properties::UpdContent,   properties, schema, strans, handler, level) if put    'updcontent'
                on resource do
                  run( Riddl::Utils::Properties::GetContent, properties, schema,         handler, level) if get
                end
              end
            end
          end  
        }
      end  

      def self::schema(fschema)
        fschema  = fschema.gsub(/^\/+/,'/')
        unless File.exists?(fschema)
          raise "schema file not found"
        end
        schema = XML::Smart.open_unprotected(fschema)
        schema.register_namespace 'p', 'http://riddl.org/ns/common-patterns/properties/1.0'
        if !File::exists?(Riddl::Utils::Properties::PROPERTIES_SCHEMA_XSL_RNG)
          raise "properties schema transformation file not found"
        end  
        strans = schema.transform_with(XML::Smart.open_unprotected(Riddl::Utils::Properties::PROPERTIES_SCHEMA_XSL_RNG))
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
        schema.find("boolean(/p:properties/p:#{property}[@modifiable='true'])") || schema.find("boolean(/p:properties/p:optional/p:#{property}[@modifiable='true'])")
      end
      def self::valid_state?(schema,property,current,new)
        schema.find("boolean(/p:properties/p:#{property}/p:#{current}/p:#{new}[@putable='true'])") || schema.find("boolean(/p:properties/p:optional/p:#{property}/p:#{current}/p:#{new}[@putable='true'])")
      end
      def self::is_state?(schema,property)
        schema.find("boolean(/p:properties/p:#{property}[@type='state'])") || schema.find("boolean(/p:properties/p:optional/p:#{property}[@type='state'])")
      end
      def self::property_type(schema,property)
        exis = schema.find("/p:properties/*[name()='#{property}']|/p:properties/p:optional/*[name()='#{property}']")
        if exis.any?
          return exis.first.attributes['type'].to_sym
        else
          return nil
        end
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

      class Properties < Riddl::Implementation #{{{
        def response
          properties = @a[0]
          schema     = @a[1]
          handler    = @a[2]
          handler.new(properties,nil).read

          ret = XML::Smart.string("<properties xmlns=\"http://riddl.org/ns/common-patterns/properties/1.0\"/>")
          schema.find("/p:properties/*[name()!='optional']|/p:properties/p:optional/*").each do |r|
            ret.root.add("property",r.qname.to_s)
          end
          return Riddl::Parameter::Complex.new("keys","text/xml",ret.to_s)
        end
      end #}}} 

      class Query < Riddl::Implementation #{{{
        def response
          properties = @a[0]
          handler    = @a[1]
          handler.new(properties,nil).read
          query = (@p[0].value.to_s.strip.empty? ? '*' : @p[0].value)

          xml = File::read(properties).gsub(/properties xmlns="[^"]+"|properties xmlns='[^']+'/,'properties')
          begin
            e = XML::Smart::string(xml).root.find(query)
          rescue => e
            prop = XML::Smart::string("<not-existing xmlns=\"http://riddl.org/ns/common-patterns/properties/1.0\"/>").to_s
            return Riddl::Parameter::Complex.new("value","text/xml",prop.to_s)
          end
          if e.class == XML::Smart::Dom::NodeSet
            if e.any?
              prop = XML::Smart::string("<value xmlns=\"http://riddl.org/ns/common-patterns/properties/1.0\"/>")
              prop.root.add(e)
            else
              prop = XML::Smart::string("<not-existing xmlns=\"http://riddl.org/ns/common-patterns/properties/1.0\"/>").to_s
            end
            return Riddl::Parameter::Complex.new("value","text/xml",prop.to_s)
          else
            return Riddl::Parameter::Simple.new("value",e.to_s)
          end
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

      class GetContent < Riddl::Implementation #{{{
        def response
          properties = @a[0]
          schema     = @a[1]
          handler    = @a[2]
          level      = @a[3]
          relpath    = @r[level..-1]
          handler.new(properties,relpath[1]).read

          if ret = extract_values(properties,schema,relpath[1],Riddl::HttpParser::unescape(relpath[2..-1].join('/')))
            ret
          else
            @status = 404
          end
        end
        
        def extract_values(file,schema,property,minor=nil)
          XML::Smart.open_unprotected(file) do |pdoc|
            pdoc.register_namespace 'p', 'http://riddl.org/ns/common-patterns/properties/1.0'
            decision = Riddl::Utils::Properties::property_type(schema,property)

            case decision
              when :complex
                res = pdoc.find("/p:properties/*[name()=\"#{property}\"]#{minor == '' ? '' : "/p:#{minor}"}")
                if res.any?
                  prop = XML::Smart::string("<value xmlns=\"http://riddl.org/ns/common-patterns/properties/1.0\"/>")
                  if res.length == 1
                    prop.root.add(res.first.children)
                  else  
                    prop.root.add(res)
                  end  
                  return Riddl::Parameter::Complex.new("value","text/xml",prop.to_s)
                else
                  prop = XML::Smart::string("<not-existing xmlns=\"http://riddl.org/ns/common-patterns/properties/1.0\"/>")
                end
              when :simple, :state
                res = pdoc.find("string(/p:properties/*[name()=\"#{property}\"]#{minor})")
                return Riddl::Parameter::Simple.new("value",res.to_s)
              when :arbitrary
                res = pdoc.find("/p:properties/*[name()=\"#{property}\"]")
                if res.any?
                  c = res.first.children
                  if c.length == 1 && c.first.class == XML::Smart::Dom::Element
                    return Riddl::Parameter::Complex.new("content","text/xml",c.first.dump)
                  else
                    return Riddl::Parameter::Complex.new("content","text/plain",c.first.to_s)
                  end
                else
                  prop = XML::Smart::string("<not-existing xmlns=\"http://riddl.org/ns/common-patterns/properties/1.0\"/>")
                  return Riddl::Parameter::Complex.new("content","text/xml",prop.to_s)
                end
            end
          end
          nil
        end
        private :extract_values

      end #}}}
      
      # Modifiable
      class AddProperty < Riddl::Implementation #{{{
        def response
          properties = @a[0]
          schema     = @a[1]
          strans     = @a[2]
          handler    = @a[3]
          level      = @a[4]
          relpath    = @r[level..-1]

          property   = @p.detect{|p| p.name == 'property'}.value

          unless Riddl::Utils::Properties::modifiable?(schema,property)
            @status = 500
            return # change properties.schema
          end

          newstuff = XML::Smart.string("<#{property} xmlns=\"http://riddl.org/ns/common-patterns/properties/1.0\"/>")
          XML::Smart.open_unprotected(properties) do |doc|
            doc.register_namespace 'p', 'http://riddl.org/ns/common-patterns/properties/1.0'

            if doc.root.find("p:#{property}").any?
              @status = 500
              return # don't misuse post
            end
            doc.root.add newstuff.root
            if !doc.validate_against(strans)
              @status = 400
              return # bad request
            end
          end

          # everything is fine, now do it
          XML::Smart::modify(properties) do |doc|
            doc.register_namespace 'p', 'http://riddl.org/ns/common-patterns/properties/1.0'
            doc.root.add newstuff.root
          end

          handler.new(properties,property).create
        end
      end #}}}

      class AddProperties < Riddl::Implementation #{{{
        def response
          properties = @a[0]
          schema     = @a[1]
          strans     = @a[2]
          handler    = @a[3]
          level      = @a[4]
          relpath    = @r[level..-1]

          0.upto(@p.length/2-1) do |i|
            property = @p[i*2].value
            ct       = @p[i*2+1]
            value    = ct.name == 'value' ? ct.value : nil
            content  = ct.name == 'content' ? ct.value : nil

            unless Riddl::Utils::Properties::modifiable?(schema,property)
              @status = 500
              return # change properties.schema
            end

            newstuff = value.nil? ? XML::Smart.string(content).root.children : value
            path = "/p:properties/*[name()=\"#{property}\"]"
            XML::Smart.open_unprotected(properties) do |doc|
              doc.register_namespace 'p', 'http://riddl.org/ns/common-patterns/properties/1.0'
              nodes = doc.find(path)
              if nodes.empty?
                @status = 404
                return # this property does not exist
              end
              if Riddl::Utils::Properties::is_state?(schema,property)
                unless Riddl::Utils::Properties::valid_state?(schema,property,nodes.first.to_s,value)
                  @status = 404
                  return # not a valid state from here on
                end
              end  
              nods = nodes.map{|ele| ele.children.delete_all!; ele}
              nods.each do |ele| 
                if value.nil?
                  ele.add newstuff
                else
                  ele.text = newstuff
                end  
              end  
              if !doc.validate_against(strans)
                @status = 400
                return # bad request
              end
            end

            XML::Smart::modify(properties) do |doc|
              doc.register_namespace 'p', 'http://riddl.org/ns/common-patterns/properties/1.0'
              nodes = doc.root.find(path)
              nods = nodes.map{|ele| ele.children.delete_all!; ele}
              nods.each do |ele| 
                if value.nil?
                  ele.add newstuff
                else
                  ele.text = newstuff
                end  
              end  
            end
            
            handler.new(properties,property).update
          end
          return
        end
      end #}}}

      class AddContent < Riddl::Implementation #{{{
        def response
          properties = @a[0]
          schema     = @a[1]
          strans     = @a[2]
          handler    = @a[3]
          level      = @a[4]
          relpath    = @r[level..-1]

          property = relpath[1]
          value = @p.detect{|p| p.name == 'value'}.value

          unless Riddl::Utils::Properties::modifiable?(schema,property)
            @status = 500
            return # change properties.schema
          end

          newstuff = XML::Smart.string(value)
          XML::Smart.open_unprotected(properties) do |doc|
            doc.register_namespace 'p', 'http://riddl.org/ns/common-patterns/properties/1.0'

            node = doc.root.find("p:#{property}")
            if node.empty?
              @status = 404
              return # this property does not exist
            end  
            node.first.add newstuff.root
            if !doc.validate_against(strans)
              @status = 400
              return # bad request
            end
          end

          # everything is fine, now do it
          XML::Smart::modify(properties) do |doc|
            doc.register_namespace 'p', 'http://riddl.org/ns/common-patterns/properties/1.0'
            node = doc.find("/p:properties/p:#{property}")
            node.first.add newstuff.root
          end

          handler.new(properties,property).create
          return
        end
      end #}}}

      class DelContent < Riddl::Implementation #{{{
        def response
          properties = @a[0]
          schema     = @a[1]
          strans     = @a[2]
          handler    = @a[3]
          level      = @a[4]
          relpath    = @r[level..-1]

          property = relpath[1]
          minor    = Riddl::HttpParser::unescape(relpath[2])

          unless Riddl::Utils::Properties::modifiable?(schema,property)
            @status = 500
            return # change properties.schema
          end


          path = "/p:properties/*[name()=\"#{property}\"]#{minor.nil? ? '' : "/p:#{minor}"}"
          XML::Smart.open_unprotected(properties) do |doc|
            doc.register_namespace 'p', 'http://riddl.org/ns/common-patterns/properties/1.0'
            nodes = doc.find(path)
            if nodes.empty?
              @status = 404
              return # this property does not exist
            end
            nodes.delete_all!
            if !doc.validate_against(strans)
              @status = 400
              return # bad request
            end
          end

          XML::Smart::modify(properties) do |doc|
            doc.register_namespace 'p', 'http://riddl.org/ns/common-patterns/properties/1.0'
            doc.find(path).delete_all!
          end

          handler.new(properties,property).delete
          return
        end
      end #}}} 

      class UpdContent < Riddl::Implementation #{{{
        def response
          properties = @a[0]
          schema     = @a[1]
          strans     = @a[2]
          handler    = @a[3]
          level      = @a[4]
          relpath    = @r[level..-1]

          property = relpath[1]
          value    = @p.detect{|p| p.name == 'value'}; value = value.nil? ? value : value.value
          content  = @p.detect{|p| p.name == 'content'}; content = content.nil? ? content : content.value
          minor    = relpath[2]

          unless Riddl::Utils::Properties::modifiable?(schema,property)
            @status = 500
            return # change properties.schema
          end

          newstuff = value.nil? ? XML::Smart.string(content).root.children : value
          path = "/p:properties/*[name()=\"#{property}\"]#{minor.nil? ? '' : "/p:#{minor}"}"
          XML::Smart.open_unprotected(properties) do |doc|
            doc.register_namespace 'p', 'http://riddl.org/ns/common-patterns/properties/1.0'
            nodes = doc.find(path)
            if nodes.empty?
              @status = 404
              return # this property does not exist
            end
            if Riddl::Utils::Properties::is_state?(schema,property)
              unless Riddl::Utils::Properties::valid_state?(schema,property,nodes.first.to_s,value)
                @status = 404
                return # not a valid state from here on
              end
            end  
            nods = nodes.map{|ele| ele.children.delete_all!; ele}
            nods.each do |ele| 
              if value.nil?
                ele.add newstuff
              else
                ele.text = newstuff
              end  
            end  
            if !doc.validate_against(strans)
              @status = 400
              return # bad request
            end
          end

          XML::Smart::modify(properties) do |doc|
            doc.register_namespace 'p', 'http://riddl.org/ns/common-patterns/properties/1.0'
            nodes = doc.root.find(path)
            nods = nodes.map{|ele| ele.children.delete_all!; ele}
            nods.each do |ele| 
              if value.nil?
                ele.add newstuff
              else
                ele.text = newstuff
              end
            end  
          end
          
          handler.new(properties,property).update
          return
        end
      end #}}}

    end
  end
end
