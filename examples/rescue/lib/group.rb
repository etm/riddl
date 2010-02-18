class GetInterface < Riddl::Implementation

  def response
    schema = RNGSchema.new
    xml = XML::Smart.open("#{@r[0..1].join("/")}/interface.xml")
    p = xml.find("/interface/properties/*") if @p[0].name == "properties"
    p = xml.find("/interface/operations/#{@r[3]}/input/*") if @p[0].name == "input"
    p = xml.find("/interface/operations/#{@r[3]}/output/*") if @p[0].name == "output"
    p.each do |e|
      schema.append_schemablock(e)
    end
    Riddl::Parameter::Complex.new("atom-feed","text/xml", p.to_s)
  end
end


class GetServiceInterface < Riddl::Implementation

  def response
    schema = RNGSchema.new
    xml = XML::Smart.open("#{@r[0..1].join("/")}/interface.xml")
    xsl = XML::Smart.open("rng+xsl/transform-group-to-service.xsl")
    Riddl::Parameter::Complex.new("atom-feed","text/xml",xml.transform_with(xsl))
  end
end

class RNGSchema
  @__schema = nil
  @__start_node = nil
  def initialize()
    @__schema = XML::Smart.string("<grammar/>")
    @__schema.root.attributes.add("xmlns", "http://relaxng.org/ns/structure/1.0")
    @__schema.root.attributes.add("typeLibrary", "http://www.w3.org/2001/XMLSchema-datatypes")
    @__schema.root.add("start")
    @__start_node = @__schema.root.children[0] 
  end

  def append_schemablock(schema_block)
    @__start_node.add(schema_block)
  end

  def to_s()
    @__schema.root.dump
  end
end
