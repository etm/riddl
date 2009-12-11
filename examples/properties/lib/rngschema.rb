class RngSchema < Riddl::Implementation

  def response
    properties = @a[0]
    schema = @a[1]
    if File::exists?(Riddl::Utils::Properties::PROPERTIES_SCHEMA_XSL_RNG)
      res = XML::Smart::open(schema).transform_with(XML::Smart::open(Riddl::Utils::Properties::PROPERTIES_SCHEMA_XSL_RNG))
      return Riddl::Parameter::Complex.new("document-schema","text/xml",res.to_s)
    end  
    @status = 404
  end  

end
