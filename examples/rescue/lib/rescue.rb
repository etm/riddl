class Workflow
  @@error_message = ""
  def self.check_syntax(xml)
    # Cheking if any input-message-parameter is referred as input for an activity that is not part of the input-message
    # Cheking if every output-message-parameter is used at least once as an output of an activity
    # Checking if any place-holder is used within a service-uri that is not defined either in the input-message or as a context-variable
    true
  end

  def self.error()
    @@error_message
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
        group = XML::Smart.open("#{@r[0..1].join("/")}/interface.xml")
        schema = XML::Smart.string(group.transform_with(XML::Smart.open("rng+xsl/generate-service-schema.xsl")))
        if xml.validate_against(schema) == false
          FileUtils.rm_r "#{@r.join("/")}/#{@p[0].value}"
          @status = 415 # Media-Type not supprted
          return
        end
        if Workflow::check_syntax(xml) == false
          @status = 415 # Media-Type not supprted
          return Riddl::Parameter::Simple.new("message", Workflow::error)
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
        begin
          File.rename("#{@r.join("/")}", "#{@r[0..-2].join("/")}/#{@p[0].value}")
        rescue
          puts $ERROR_INFO
          @status = 409
          return
        end
      elsif @p[0].name == "properties"
        xml = XML::Smart.string(@p[0].value.read)
        group = XML::Smart.open("#{@r[0..1].join("/")}/interface.xml")
        schema = XML::Smart.string(group.transform_with(XML::Smart.open("rng+xsl/generate-service-schema.xsl")))
        if xml.validate_against(schema) == false
          @status = 415 # Media-Type not supprted
          return
        end
        if Workflow::check_syntax(xml) == false
          @status = 415 # Media-Type not supprted
          return Riddl::Parameter::Simple.new("message", Workflow::error)
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

class GetOperationWorkflow < Riddl::Implementation

  def response
    xml = XML::Smart.open("#{@r[0..-2].join("/")}/properties.xml")
    wf = xml.find("/service:service-details/service:operations/service:#{@r[-1]}", {"service" => "http://rescue.org/ns/service/0.2"}).first
    if wf == nil
      @status = 404 # not found
      return
    end
    Riddl::Parameter::Complex.new("workflow","text/xml", wf.dump)
  end
end

class GetInterface < Riddl::Implementation

  def response
    schema = RNGSchema.new
    p = nil
    xml = XML::Smart.open("#{@r[0..1].join("/")}/interface.xml")
    p = xml.find("/group:interface/group:properties", {"group" => "http://rescue.org/ns/group/0.2"}) if @p[0].name == "properties"
    p = XML::Smart.string(xml.transform_with(XML::Smart.open("rng+xsl/generate-messages-schema.xsl"))) if @p[0].name != "properties"
    p = p.root.find("//group:#{@r[3]}/rng:element[@name='input-message']",  {"rng" => "http://relaxng.org/ns/structure/1.0", "group" => "http://rescue.org/ns/group/0.2"}) if @p[0].name == "input"
    p = p.root.find("//group:#{@r[3]}/rng:element[@name='output-message']",  {"rng" => "http://relaxng.org/ns/structure/1.0", "group" => "http://rescue.org/ns/group/0.2"}) if @p[0].name == "output"
    if p.first == nil
      @status = 404 # not found
      return
    end
    p.each do |e|
      schema.append_schemablock(e)
    end
    Riddl::Parameter::Complex.new("atom-feed","text/xml", schema.to_s)
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
    @__schema.root.attributes.add("datatypeLibrary", "http://www.w3.org/2001/XMLSchema-datatypes")
    @__schema.root.add("start")
    @__start_node = @__schema.root.children[0] 
  end

  def append_schemablock(schema_block)
    captions = schema_block.find("//caption")
    captions.delete_if!{true}
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
    Riddl::Parameter::Complex.new("service","text/xml",File.open("#{@r.join("/")}/properties.xml", "r"))
  end
end


