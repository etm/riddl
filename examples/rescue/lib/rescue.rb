class GetMethods < Riddl::Implementation
  def response
    xml = XML::Smart.open("#{@r[0..1].join("/")}/interface.xml")
    schema = RNGSchema.new

    schema.append_schemablock(xml.find("/domain:domain-description/domain:methods", {"domain"=>"http://rescue.org/ns/domain/0.2", "rng" => "http://relaxng.org/ns/structure/1.0"}).first)
    Riddl::Parameter::Complex.new("xml","text/xml", schema.to_s)
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
=begin
      if Execution::check_syntax(xml, interface) == false
          @status = 415 # Media-Type not supprted
          puts "Execution-Syntax-Error:" 
          puts Execution::error
          return Riddl::Parameter::Simple.new("error-message", Execution::error)
        end
=end
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
=begin
        if Execution::check_syntax(xml, interface) == false
          @status = 415 # Media-Type not supprted
          return Riddl::Parameter::Simple.new("error-message", Execution::error)
        end
=end
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
    schema = RNGSchema.new
    p = nil
    xml = XML::Smart.open("#{@r[0..1].join("/")}/interface.xml")
    params = nil

    if @r[4] != "execute" &&
       @r[4] != "compensate" &&
       @r[4] != "undo" &&
       @r[4] != "redo" &&
       @r[4] != "suspend" &&
       @r[4] != "abort"
      @status = 404 # not foud
      return
    end

    if @p[0].name == "properties"
      schema.append_schemablock(xml.find("/domain:domain-description/domain:properties", {"domain" => "http://rescue.org/ns/domain/0.2"}).first)
    else 
      input = collect_input(@r[3], @r[4], xml)
      output = collect_output(@r[3], @r[4], xml)
      if input.length == 0 && output.length == 0
        @status = 404 # not found
        return
      end
      s = nil
      if @p[0].name == "input"
        s = XML::Smart.string("<rng:element name='input-message' xmlns:rng='http://relaxng.org/ns/structure/1.0'/>")
        input.delete_if{|k,v| output.key?(k)}
        params = input
      end
      
      if @p[0].name == "output"
        s = XML::Smart.string("<rng:element name='output-message' xmlns:rng='http://relaxng.org/ns/structure/1.0'/>")
        output.delete_if{|k,v| input.key?(k)}
        params = output
      end
      params.sort.each do |k,v|
        s.root.add(v)
      end
      schema.append_schemablock(s.root)
    end 
    Riddl::Parameter::Complex.new("schema","text/xml", schema.to_s)
  end

  def collect_input(method_name, operation_name, xml)
    params = Hash.new
    xml.find("/domain:domain-description/domain:methods/domain:method[@name='#{method_name}']/domain:#{operation_name}/descendant::exec:call", 
            {"domain" => "http://rescue.org/ns/domain/0.2", "rng" => "http://relaxng.org/ns/structure/1.0", "exec"=>"http://rescue.org/ns/execution/0.2"}).each do |call|
      params.merge!(collect_input(call.attributes.get_attr("service-method").value, operation_name, xml)) if call.attributes.include?("service-method") && method_name != call.attributes.get_attr("service-method").value # Call refers to another method of the service
      call.find("descendant::exec:input", {"exec"=>"http://rescue.org/ns/execution/0.2"}).each do |input|
        if input.attributes.include?("message") # call uses a message
          xml.find("/domain:domain-description/domain:messages/domain:message[@name='#{input.attributes.get_attr("message")}']/rng:*",
                  {"domain" => "http://rescue.org/ns/domain/0.2", "rng" => "http://relaxng.org/ns/structure/1.0", "exec"=>"http://rescue.org/ns/execution/0.2"}).each do |p|
            params[p.attributes.get_attr("name").value] = p if p.name.name == "element" # use element
            params["ZoM" + p.children[0].attributes.get_attr("name").value] = p if p.name.name == "zeroOrMore" # use zeroOrMore-block
          end
        end
      end  
    end
    params
  end

  def collect_output(method_name, operation_name, xml)
    params = Hash.new
    xml.find("/domain:domain-description/domain:methods/domain:method[@name='#{method_name}']/domain:#{operation_name}/descendant::exec:call", 
            {"domain" => "http://rescue.org/ns/domain/0.2", "rng" => "http://relaxng.org/ns/structure/1.0", "exec"=>"http://rescue.org/ns/execution/0.2"}).each do |call|
      params.merge!(collect_output(call.attributes.get_attr("service-method").value, operation_name, xml)) if call.attributes.include?("service-method") && method_name != call.attributes.get_attr("service-method").value # Call refers to another method of the service
      call.find("descendant::exec:output", {"exec"=>"http://rescue.org/ns/execution/0.2"}).each do |output|
        if output.attributes.include?("message") # call uses a message
          xml.find("/domain:domain-description/domain:messages/domain:message[@name='#{output.attributes.get_attr("message")}']/rng:*",
                  {"domain" => "http://rescue.org/ns/domain/0.2", "rng" => "http://relaxng.org/ns/structure/1.0", "exec"=>"http://rescue.org/ns/execution/0.2"}).each do |p|
            params[p.attributes.get_attr("name").value] = p if p.name.name == "element" # use element
            params["ZoM" + p.children[0].attributes.get_attr("name").value] = p if p.name.name == "zeroOrMore" # use zeroOrMore-block
          end
        end
      end  
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

  def initialize()
    @__schema = XML::Smart.string("<grammar/>")
    @__schema.root.attributes.add("xmlns", "http://relaxng.org/ns/structure/1.0")
    @__schema.root.attributes.add("xmlns:rng", "http://relaxng.org/ns/structure/1.0")
    @__schema.root.attributes.add("xmlns:domain", "http://rescue.org/ns/domain/0.2")
    @__schema.root.attributes.add("xmlns:service", "http://rescue.org/ns/service/0.2")
    @__schema.root.attributes.add("xmlns:exec", "http://rescue.org/ns/execution/0.2")
    @__schema.root.attributes.add("xmlns:wf", "http://rescue.org/ns/workflow/0.2")
    @__schema.root.attributes.add("datatypeLibrary", "http://www.w3.org/2001/XMLSchema-datatypes")
    @__schema.root.add("start")
    @__start_node = @__schema.root.children[0] 
  end

  def append_schemablock(schema_block)
    captions = schema_block.find("//domain:caption", {"domain" => "http://rescue.org/ns/domain/0.2"})
    captions.delete_if!{true} if captions != nil
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

class GetDescription < Riddl::Implementation

  def response
    if File.exist?("description.xml") == false
      puts "Can not read description.xml"
      @status = 410 # 410: Gone
      return
    end
    Riddl::Parameter::Complex.new("description","text/xml", File.open("description.xml", "r"))
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
      feed__ :xmlns => 'http://www.w3.org/2005/Atom' do
        title_ "Resourcelist at #{url}#{@r.join("/")}"
        updated_ File.mtime("#{@r.join("/")}").xmlschema
        generator_ 'RESCUE', :uri => "#{url}"
        id_ "#{url}#{@r.join("/")}/"
        link_ :rel => 'self', :type => 'application/atom+xml', :href => "#{url}#{@r.join("/")}/"
        parse_interface(@r[1], url) if @r.length > 1
        groups.each do |g|
          entry_ do 
            title_ "#{g}"
            author_ do name_ "RESCUE" end
            id_ "#{url}#{@r.join("/")}/#{g}/"
            link_ g, :href=>"#{url}#{@r.join("/")}/#{g}/"
            updated_ File.mtime("#{@r.join("/")}/#{g}").xmlschema
          end
        end
      end
    end
  end

  def parse_interface(group_name, url)
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
    Riddl::Parameter::Complex.new("service-description","text/xml",File.open("#{@r.join("/")}/properties.xml", "r"))
  end
end


