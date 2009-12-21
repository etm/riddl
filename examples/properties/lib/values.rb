class Values < Riddl::Implementation
  include Riddl::Utils::Properties

  def response
    properties = @a[0]
    schema = @a[1]
    if ret = extract_values(properties,schema,@r[1],@r[2])
      ret 
    else
      @status = 404
    end  
  end  

end  
