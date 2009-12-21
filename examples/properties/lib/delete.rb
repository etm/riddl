class Delete < Riddl::Implementation

  def response
    properties = @a[0]
    schema = @a[1]
    
    key = @r[1]
    property = @r[2]

    path = "p:#{key}" + (property.nil? ? '' : "/p:#{property}")

    XML::Smart::open(properties) do |doc|
      doc.namespaces = { 'p' => 'http://riddl.org/ns/common-patterns/properties/1.0' }
      nodes = doc.root.find(path)
      if nodes.empty?
        @status = 404
        return # this property does not exist
      end  
      nodes.delete_all!
      res = XML::Smart::open(schema).transform_with(XML::Smart::open(Riddl::Utils::Properties::PROPERTIES_SCHEMA_XSL_RNG))
      if !doc.validate_against(XML::Smart::string(res))
        @status = 400
        return # bad request
      end
    end
    
    XML::Smart::modify(properties) do |doc|
      doc.namespaces = { 'p' => 'http://riddl.org/ns/common-patterns/properties/1.0' }
      doc.root.find(path).delete_all!
    end  
    return
  end  
  
end
