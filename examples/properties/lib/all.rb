class All < Riddl::Implementation

  def response
    properties = @a[0]
    schema = @a[1]

    return Riddl::Parameter::Complex.new("document","text/xml",File::open(properties))
  end  

end
