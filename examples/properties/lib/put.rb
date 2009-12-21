class Put < Riddl::Implementation

  def response
    properties = @a[0]
    schema = @a[1]
    value = @p.detect{|p| p.name == 'value'}.value
    
    key = @r[1]
    property = @r[2]

    path = "p:#{key}" + (property.nil? ? '' : "/p:#{property}")
    pname = property.nil? ? key : property

    begin

    newstuff = XML::Smart.string("<#{pname} xmlns=\"http://riddl.org/ns/common-patterns/properties/1.0\">#{value}</#{pname}>")
    XML::Smart::open(properties) do |doc|
      doc.namespaces = { 'p' => 'http://riddl.org/ns/common-patterns/properties/1.0' }
      nodes = doc.root.find(path)
      if nodes.empty?
        @status = 404
        return # this property does not exist
      end
      parent = nodes.first.parent
      nodes.delete_all!
      parent.add(newstuff.root)
      res = XML::Smart::open(schema).transform_with(XML::Smart::open(Riddl::Utils::Properties::PROPERTIES_SCHEMA_XSL_RNG))
      if !doc.validate_against(XML::Smart::string(res))
        @status = 400
        return # bad request
      end
    end

    rescue => e
      p e
      puts e.backtrace
      p "---"
    end  
    
    XML::Smart::modify(properties) do |doc|
      doc.namespaces = { 'p' => 'http://riddl.org/ns/common-patterns/properties/1.0' }
      nodes = doc.root.find(path)
      parent = nodes.first.parent
      doc.root.find(path).delete_all!
      parent.add(newstuff.root)
    end  
    return
  end  
  
end
