class GetOperations < Riddl::Implementation
  def response
    if not File.exists?("#{@r[0..1].join("/")}/interface.xml")
      @status = 410
      return
    end
    xml = XML::Smart.open("#{@r[0..1].join("/")}/interface.xml")
    ret = XML::Smart.string("<operations xmlns=\"http://rescue.org/ns/domain/0.2\"/>")
    xml.find("/domain:domain-description/domain:operations/*", {"domain"=>"http://rescue.org/ns/domain/0.2", "rng" => "http://relaxng.org/ns/structure/1.0"}).each do |o|
      ret.root.add("operation", {"name" => o.attributes["name"]})
    end
    Riddl::Parameter::Complex.new("xml","text/xml", ret.to_s)
  end
end

class AddResource < Riddl::Implementation
  def response
    begin
      f = nil
      c = nil
      FileUtils.mkdir "#{@r.join("/")}/#{@p[0].value}"
      if @p[0].name == "group-name"
        f = File.new("#{@r.join("/")}/#{@p[0].value}/interface.xml", "w")
        c = @p[1].value.read
      elsif @p[0].name == "service-name"
        c = @p[1].value.read
        # Check if parameter matches the schema generate for this group
        xml = XML::Smart.string(c)
        interface = XML::Smart.open("#{@r[0..1].join("/")}/interface.xml")
        schema = XML::Smart.string(interface.transform_with(XML::Smart.open("rng+xsl/generate-service-schema.xsl")))
        if xml.validate_against(schema) == false
          FileUtils.rm_r "#{@r.join("/")}/#{@p[0].value}"
          @status = 415 # Media-Type not supprted
          return
        end
        f = File.new("#{@r.join("/")}/#{@p[0].value}/properties.xml", "w")
      end
      if @p[0].name != "subgroup-name"
        f.write(c)
        f.close()
      end
      @status = 201  # 201: Created
    rescue
      puts $ERROR_INFO
      @status = 409 # http ERROR named 'Conflict'
    end
  end
end

class UpdateResource < Riddl::Implementation
  def response
    begin
      if @p[0].name == "new-name"
        if File.directory?(@r.join("/")) == false
          @status = 410
          return
        end
        begin
          File.rename("#{@r.join("/")}", "#{@r[0..-2].join("/")}/#{@p[0].value}")
        rescue
          puts $ERROR_INFO
          @status = 409
          return
        end
      elsif @p[0].name == "service-description"
        xml = XML::Smart.string(@p[0].value.read)
        interface = XML::Smart.open("#{@r[0..1].join("/")}/interface.xml")
        schema = XML::Smart.string(interface.transform_with(XML::Smart.open("rng+xsl/generate-service-schema.xsl")))
        if xml.validate_against(schema) == false
          @status = 415 # Media-Type not supprted
          return
        end
        f = File.new("#{@r.join("/")}/properties.xml", "w")
        f.write(xml)
        f.close()
      end
    rescue
      @status = 500 # Something that should not happen, happend 
      puts $ERROR_INFO
    end
  end
end

class GetInterface < Riddl::Implementation
  def response
    schema = RNGSchema.new(false)
    p = nil
    if not File.exists?("#{@r[0..1].join("/")}/interface.xml")
      @status = 410
      return
    end
    xml = XML::Smart.open("#{@r[0..1].join("/")}/interface.xml")
    params = nil
    out_name = "schema"


    if @p[0] == nil # If no parameter is given, the defition of the class-level-workflow 
      schema = XML::Smart.string("<operation name='#{@r[-1]}' xmlns=\"http://rescue.org/ns/controlflow/0.2\"/>")
      o = xml.find("/domain:domain-description/domain:operations/flow:operation[@name='#{@r[-1]}']/flow:*", {"domain" => "http://rescue.org/ns/domain/0.2", "flow"=>"http://rescue.org/ns/controlflow/0.2"})
      if o.first.nil?
        @status = 410 
        return
      end
      schema.root.add(o)
      out_name = "class-level-workflow"
    elsif @p[0].name == "properties"
      schema.append_schemablock(xml.find("/domain:domain-description/domain:properties", {"domain" => "http://rescue.org/ns/domain/0.2"}).first)
    else 
      input = collect_input(@r[-1], xml)
      output = collect_output(@r[-1], xml)
      if input.length == 0 && output.length == 0
        @status = 404 # not found
        return
      end
      s = nil
      # Select input of all state-controlflows with an given operation and remove all call-outputs
      if @p[0].name == "input"
        s = XML::Smart.string("<rng:element name='input-message' xmlns:rng='http://relaxng.org/ns/structure/1.0'/>")
        input.delete_if{|k,v| output.key?(k)}
        params = input
        ep_node = Hash.new 
        ep_xml = nil
        xml.find("//flow:operation[@name='#{@r[-1]}']/descendant::flow:call[@endpoint-type = 'outside']", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).each do |call|
          if ep_node[call.attributes['endpoint']].nil?
            ep_node[call.attributes['endpoint']] = call.attributes['id']
          else
            ep_node[call.attributes['endpoint']] << ", #{call.attributes['id']}"
          end
        end
        if ep_node.length > 0
          ep_xml = XML::Smart.string("<rng:element name='additional_endpoints' xmlns:rng='http://relaxng.org/ns/structure/1.0'/>")
          ep_node.each do |k,v|  
            node = ep_xml.root.add("element", {"name"=>k})
            c = node.add("caption", "Used at call(s): #{v}")
            c.namespaces.add("domain", "http://rescue.org/ns/domain/0.2")
          end
        end
        schema.append_schemablock(ep_xml.root) if ep_xml
      end
      
      # Select output of all state-controlflows with an given operation and remove all call-inputs
      if @p[0].name == "output"
        s = XML::Smart.string("<rng:element name='output-message' xmlns:rng='http://relaxng.org/ns/structure/1.0'/>")
        output.delete_if{|k,v| input.key?(k)}
        params = output
      end
      params.each do |k,v|
        s.root.add(v)
      end
      schema.append_schemablock(s.root)
    end 
    Riddl::Parameter::Complex.new(out_name,"text/xml", schema.to_s)
  end

  def collect_input(operation_name, xml)
    params = Hash.new
    xml.find("//flow:operation[@name='#{operation_name}']/descendant::flow:call/flow:input", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).each do |input|
      params[input.attributes['message-parameter']] = input.children.first if input.attributes.include?('message-parameter')
    end
    params
  end

  def collect_output(operation_name, xml)
    params = Hash.new
    xml.find("//flow:operation[@name='#{operation_name}']/descendant::flow:call/flow:output", {"flow"=>"http://rescue.org/ns/controlflow/0.2"}).each do |output|
      params[output.attributes['message-parameter']] = output.children.first if output.attributes.include?('message-parameter')
    end
    params
  end
end


class GetServiceInterface < Riddl::Implementation

  def response
    begin
      xml = XML::Smart.open("#{@r[0..1].join("/")}/interface.xml")
      xsl = XML::Smart.open("rng+xsl/generate-service-schema.xsl")
      Riddl::Parameter::Complex.new("schema","text/xml",xml.transform_with(xsl))
    rescue
      @status = 410 # Gone
      puts $ERROR_INFO
    end
  end
end

class RNGSchema
  @__schema = nil
  @__start_node = nil
  @__remove_cpations = nil

  def initialize(remove_captions)
    @__remove_captions = remove_captions
    @__schema = XML::Smart.string("<grammar/>")
    @__schema.root.namespaces.add("datatypeLibrary", "http://www.w3.org/2001/XMLSchema-datatypes")
    @__schema.root.namespaces.add("rng", "http://relaxng.org/ns/structure/1.0")
    @__schema.root.add("start")
    @__start_node = @__schema.root.children[0] 
  end

  def append_schemablock(schema_block)
    captions = schema_block.find("//domain:caption", {"domain" => "http://rescue.org/ns/domain/0.2"})
    captions.delete_if!{true} if captions != nil and @__remove_captions == true
    @__start_node.add(schema_block)
  end

  def add_wrapper_node(name, attributes, value)
    @__start_node.add(name, attributes, value)
    @__start_node = @__start_node.children[0]
  end 

  def to_s()
    @__schema.root.dump
  end
end

class DeleteResource < Riddl::Implementation
  def response
    begin
      FileUtils.rm_r @r.join("/")
    rescue
      @status = 404
      puts $ERRO_INFO
    end
  end
end

class GenerateFeed < Riddl::Implementation
  include MarkUSModule

  def response
    url = "http://" + @env['HTTP_HOST'] + "/"
    groups = Array.new
    if File.exists?("#{@r.join("/")}") == false
      @status = 410
      return
    end
    Dir["#{@r.join("/")}/*"].sort.each do |f|
      groups << File::basename(f) if File::directory? f
    end
    Riddl::Parameter::Complex.new("atom-feed","text/xml") do
      text_! "<?xml-stylesheet href=\"http://localhost:9290/xsl/instances.xsl\" type=\"text/xsl\"?>"
      feed_ :xmlns => 'http://www.w3.org/2005/Atom' do
        title_ "Resourcelist at #{url}#{@r.join("/")}"
        updated_ File.mtime("#{@r.join("/")}").xmlschema
        generator_ 'RESCUE', :uri => "#{url}"
        id_ "#{url}#{@r.join("/")}/"
        link_ :rel => 'self', :type => 'application/atom+xml', :href => "#{url}#{@r.join("/")}/"
        parse_interface(@r[1], url) if @r.length > 1
        groups.each do |g|
          entry_ do 
            title_ "#{g}"
            author_ do name_ "RESCUEv0.2" end
            id_ "#{url}#{@r.join("/")}/#{g}/"
            link_ g, :href=>"#{url}#{@r.join("/")}/#{g}/"
            updated_ File.mtime("#{@r.join("/")}/#{g}").xmlschema
          end
        end
      end
    end
  end

  def parse_interface(group_name, url)
    if not File.exists?("groups/#{group_name}/interface.xml")
      @status = 410
      return
    end
    xml = XML::Smart.open("groups/#{group_name}/interface.xml")
    schema_ do
      operations = xml.find("/interface/operations/*")
      operations.each do |o|
        operation_ :name=>"#{o.name.name}" do
          message_ :type=>"input", :href=>"#{url}/groups/#{group_name}/operations/#{o.name.name}?input"
          message_ :type=>"output", :href=>"#{url}/groups/#{group_name}/operations/#{o.name.name}?output"
        end
      end
      properties_ :href=>"#{url}/groups/#{group_name}?properties"
    end
  end
end

class GetServiceDescription <  Riddl::Implementation
  def response
    if File.exist?("#{@r.join("/")}/properties.xml") == false
      @status = 410
      return
    end
    Riddl::Parameter::Complex.new("instance-level-workflow","text/xml",File.open("#{@r.join("/")}/properties.xml", "r"))
  end
end


