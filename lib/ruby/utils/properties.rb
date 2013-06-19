module Riddl
  module Utils
    module Properties

      VERSION_MAJOR = 1
      VERSION_MINOR = 0
      PROPERTIES_SCHEMA_XSL_RNG = "#{File.dirname(__FILE__)}/../ns/common-patterns/properties/#{VERSION_MAJOR}.#{VERSION_MINOR}/properties.schema.xsl"

      def self::implementation(backend,handler=nil,details=:production)
        unless handler.nil? || (handler.class == Class && handler.superclass == Riddl::Utils::Properties::HandlerBase)
          raise "handler not a subclass of HandlerBase"
        end
        Proc.new do
          run          Riddl::Utils::Properties::All,           backend, handler if get    '*'
          run          Riddl::Utils::Properties::Query,         backend, handler if get    'query'
          on resource 'schema' do
            run        Riddl::Utils::Properties::Schema,        backend          if get
            on resource 'rng' do
              run      Riddl::Utils::Properties::RngSchema,     backend          if get
            end  
          end
          on resource 'values' do
            run        Riddl::Utils::Properties::Properties,    backend, handler if get
            run        Riddl::Utils::Properties::AddProperty,   backend, handler if post   'property'
            run        Riddl::Utils::Properties::AddProperties, backend, handler if put    'properties'
            on resource do
              run      Riddl::Utils::Properties::GetContent,    backend, handler if get
              run      Riddl::Utils::Properties::DelContent,    backend, handler if delete
              run      Riddl::Utils::Properties::AddContent,    backend, handler if post   'addcontent'
              run      Riddl::Utils::Properties::UpdContent,    backend, handler if put    'updcontent'
              on resource do
                run    Riddl::Utils::Properties::GetContent,    backend, handler if get
                run    Riddl::Utils::Properties::DelContent,    backend, handler if delete
                run    Riddl::Utils::Properties::UpdContent,    backend, handler if put    'updcontent'
                on resource do
                  run  Riddl::Utils::Properties::GetContent,    backend, handler if get
                end
              end
            end
          end  
        end
      end  

      # Overloadable and Backends
      class HandlerBase #{{{
        def initialize(backend,property)
          @backend = backend
          @property = property
        end
        def create; end
        def read;   end
        def update; end
        def delete; end
      end #}}}

      class Backend #{{{
        attr_reader :schema, :properties, :rng, :id

        def initialize(schema,target,id=nil)
          @id = id
          @schemas = {}
          @rngs = {}

          if schema.is_a? Hash
            schema.each { |k,v| add_schema k, v }
          elsif schema.is_a? String  
            add_schema 'default', schema
          end
          raise "no schemas provided" if @schemas.length == 0
          @schema = @schemas.first[1]
          @rng = @rngs.first[1]

          raise "properties file not found" unless File.exists?(target)
          @target = target.gsub(/^\/+/,'/')
          @properties = XML::Smart.open_unprotected(target)
          @properties.register_namespace 'p', 'http://riddl.org/ns/common-patterns/properties/1.0'
          @mutex = Mutex.new
        end

        def activate_schema(name)
          if @schemas[name]
            @schema = @schemas[name][1]
            @rng = @schemas[name][1]
            true
          else
            false
          end
        end

        def add_schema(id,name)
          raise "schema file not found" unless File.exists?(name)
          @schemas[id] = XML::Smart.open_unprotected(name.gsub(/^\/+/,'/'))
          @schemas[id].register_namespace 'p', 'http://riddl.org/ns/common-patterns/properties/1.0'
          if !File::exists?(Riddl::Utils::Properties::PROPERTIES_SCHEMA_XSL_RNG)
            raise "properties schema transformation file not found"
          end  
          @rngs[id] = @schemas[id].transform_with(XML::Smart.open_unprotected(Riddl::Utils::Properties::PROPERTIES_SCHEMA_XSL_RNG))
        end
        private :add_schema

        def modifiable?(property)
          @schema.find("boolean(/p:properties/p:#{property}[@modifiable='true'])") || schema.find("boolean(/p:properties/p:optional/p:#{property}[@modifiable='true'])")
        end
        def valid_state?(property,current,new)
          @schema.find("boolean(/p:properties/p:#{property}/p:#{current}/p:#{new}[@putable='true'])") || schema.find("boolean(/p:properties/p:optional/p:#{property}/p:#{current}/p:#{new}[@putable='true'])")
        end
        def is_state?(property)
          @schema.find("boolean(/p:properties/p:#{property}[@type='state'])") || schema.find("boolean(/p:properties/p:optional/p:#{property}[@type='state'])")
        end
        def init_state?(property,new)
          @schema.find("boolean(/p:properties/p:#{property}/p:#{new}[position()=1])") || schema.find("boolean(/p:properties/p:optional/p:#{property}/p:#{new}[position()=1])")
        end
        def property_type(property)
          exis = @schema.find("/p:properties/*[name()='#{property}']|/p:properties/p:optional/*[name()='#{property}']")
          exis.any? ? exis.first.attributes['type'].to_sym : nil
        end

        def modify(&block)
          tdoc = @properties.root.to_doc
          tdoc.register_namespace 'p', 'http://riddl.org/ns/common-patterns/properties/1.0'
          @mutex.synchronize do
            block.call tdoc
            if tdoc.validate_against(@rng)
              block.call @properties
              @properties.save_as(@target)
              true
            else
              false
            end
          end  
        end
       end #}}}

      # Just reading
      class All < Riddl::Implementation #{{{
        def response
          backend = @a[0]
          handler = @a[1]
          handler.new(backend,nil).read unless handler.nil?
          return Riddl::Parameter::Complex.new("document","text/xml",backend.properties.to_s)
        end
      end #}}}

      class Properties < Riddl::Implementation #{{{
        def response
          backend = @a[0]
          handler = @a[1]
          handler.new(backend,nil).read unless handler.nil?

          ret = XML::Smart.string("<properties xmlns=\"http://riddl.org/ns/common-patterns/properties/1.0\"/>")
          backend.schema.find("/p:properties/*[name()!='optional']|/p:properties/p:optional/*").each do |r|
            ret.root.add("property",r.qname.to_s)
          end
          return Riddl::Parameter::Complex.new("keys","text/xml",ret.to_s)
        end
      end #}}} 

      class Query < Riddl::Implementation #{{{
        def response
          backend = @a[0]
          handler = @a[1]
          handler.new(backend,nil).read unless handler.nil?
          query = (@p[0].value.to_s.strip.empty? ? '*' : @p[0].value)

          begin
            e = backend.properties.find(query)
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
          backend = @a[0]
          Riddl::Parameter::Complex.new("document-schema","text/xml",backend.rng.to_s)
        end
      end #}}}

      class Schema < Riddl::Implementation #{{{
        def response
          backend = @a[0]
          return Riddl::Parameter::Complex.new("document-schema","text/xml",backend.schema.to_s)
        end
      end #}}}

      class GetContent < Riddl::Implementation #{{{
        def response
          backend = @a[0]
          handler = @a[1]

          handler.new(backend,@r[1]).read unless handler.nil?

          if ret = extract_values(backend,@r[1],Riddl::Protocols::HTTP::Parser::unescape(@r[2..-1].join('/')))
            ret
          else
            @status = 404
          end
        end
        
        def extract_values(backend,property,minor=nil)
          case backend.property_type(property)
            when :complex
              res = backend.properties.find("/p:properties/*[name()=\"#{property}\"]#{minor == '' ? '' : "/p:#{minor}"}")
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
              res = backend.properties.find("string(/p:properties/*[name()=\"#{property}\"]#{minor})")
              return Riddl::Parameter::Simple.new("value",res.to_s)
            when :arbitrary
              res = backend.properties.find("/p:properties/*[name()=\"#{property}\"]")
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
          nil
        end
        private :extract_values

      end #}}}
      
      # Modifiable
      class AddProperty < Riddl::Implementation #{{{
        def response
          backend = @a[0]
          handler = @a[1]

          property = @p[0].value
          ct       = @p[1]
          value    = ct.name == 'value' ? ct.value : nil
          content  = ct.name == 'content' ? ct.value : nil

          unless backend.modifiable?(property)
            @status = 500
            return # change properties.schema
          end

          path = "/p:properties/*[name()=\"#{property}\"]"
          nodes = backend.properties.find(path)
          if nodes.any?
            @status = 404
            return # this property does not exist
          end

          if backend.is_state?(property)
            unless backend.init_state?(property,value)
              @status = 404
              return # not a valid state from here on
            end
          end  

          newstuff = value.nil? ? XML::Smart.string(content).root.children : value
          backend.modify do |doc|
            ele = doc.root.add property
            if value.nil?
              ele.add newstuff
            else
              ele.text = newstuff
            end  
          end || begin
            @status = 400
            return # bad request
          end
          
          handler.create(backend,property).update unless handler.nil?
          return
        end
      end #}}}
      
      class AddProperties < Riddl::Implementation #{{{
        def response
          backend = @a[0]
          handler = @a[1]

          0.upto(@p.length/2-1) do |i|
            property = @p[i*2].value
            ct       = @p[i*2+1]
            value    = ct.name == 'value' ? ct.value : nil
            content  = ct.name == 'content' ? ct.value : nil

            unless backend.modifiable?(property)
              @status = 500
              return # change properties.schema
            end

            path = "/p:properties/*[name()=\"#{property}\"]"
            nodes = backend.properties.find(path)
            if nodes.empty?
              @status = 404
              return # this property does not exist
            end

            if backend.is_state?(property)
              unless backend.valid_state?(property,nodes.first.to_s,value)
                @status = 404
                return # not a valid state from here on
              end
            end  

            newstuff = value.nil? ? XML::Smart.string(content).root.children : value
            backend.modify do |doc|
              nodes = doc.find(path)
              nods = nodes.map{|ele| ele.children.delete_all!; ele}
              nods.each do |ele| 
                if value.nil?
                  ele.add newstuff
                else
                  ele.text = newstuff
                end  
              end  
            end || begin
              @status = 400
              return # bad request
            end
            
            handler.new(backend,property).update unless handler.nil?
          end
          return
        end
      end #}}}

      class AddContent < Riddl::Implementation #{{{
        def response
          backend = @a[0]
          handler = @a[1]

          property = @r[1]
          value = @p.detect{|p| p.name == 'value'}.value

          unless backend.modifiable?(property)
            @status = 500
            return # change properties.schema
          end

          path = "/p:properties/p:#{property}"
          node = backend.properties.find(path)
          if node.empty?
            @status = 404
            return # this property does not exist
          end  

          newstuff = XML::Smart.string(value)
          backend.modify do |doc|
            node = doc.find(path)
            node.first.add newstuff.root
          end || begin
            @status = 400
            return # bad request
          end

          handler.new(backend,property).create unless handler.nil?
        end
      end #}}}

      class DelContent < Riddl::Implementation #{{{
        def response
          backend = @a[0]
          handler = @a[1]

          property = @r[1]
          minor    = Riddl::Protocols::HTTP::Parser::unescape(@r[2])

          unless backend.modifiable?(property)
            p 'aaaa'
            @status = 500
            return # change properties.schema
          end

          path = "/p:properties/*[name()=\"#{property}\"]#{minor.nil? ? '' : "/p:#{minor}"}"
          nodes = backend.properties.find(path)
          if nodes.empty?
            @status = 404
            return # this property does not exist
          end

          backend.modify do |doc|
            doc.find(path).delete_all!
          end || begin
            @status = 400
            return # bad request
          end

          handler.new(backend,property).delete unless handler.nil?
          return
        end
      end #}}} 

      class UpdContent < Riddl::Implementation #{{{
        def response
          backend = @a[0]
          handler = @a[1]

          property = @r[1]
          value    = @p.detect{|p| p.name == 'value'}; value = value.nil? ? value : value.value
          content  = @p.detect{|p| p.name == 'content'}; content = content.nil? ? content : content.value
          minor    = @r[2]

          unless backend.modifiable?(property)
            @status = 500
            return # change properties.schema
          end

          path = "/p:properties/*[name()=\"#{property}\"]#{minor.nil? ? '' : "/p:#{minor}"}"
          nodes = backend.properties.find(path)
          if nodes.empty?
            @status = 404
            return # this property does not exist
          end

          if backend.is_state?(property)
            unless backend.valid_state?(property,nodes.first.to_s,value)
              @status = 404
              return # not a valid state from here on
            end
          end  

          newstuff = value.nil? ? XML::Smart.string(content).root.children : value
          backend.modify do |doc|
            nodes = doc.root.find(path)
            nods = nodes.map{|ele| ele.children.delete_all!; ele}
            nods.each do |ele| 
              if value.nil?
                ele.add newstuff
              else
                ele.text = newstuff
              end
            end  
          end || begin
            @status = 400
            return # bad request
          end
          
          handler.new(backend,property).update unless handler.nil?
          return
        end
      end #}}}

    end
  end
end
