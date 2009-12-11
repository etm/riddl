class Schema < Riddl::Implementation

  def response
    properties = @a[0]
    schema = @a[1]
    return Riddl::Parameter::Complex.new("document-schema","text/xml",File::open(schema))
  end  

end
