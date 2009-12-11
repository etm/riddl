class AddPair < Riddl::Implementation

  def response
    properties = @a[0]
    schema = @a[1]
    key = @p.detect{|p| p.name == 'key'}.value
    value = @p.detect{|p| p.name == 'value'}.value

    property = @r[1]

    newstuff = XML::Smart.string("<#{key} xmlns=\"http://riddl.org/ns/common-patterns/properties/1.0\">#{value}</#{key}>")
    XML::Smart::open(properties) do |doc|
      doc.namespaces = { 'p' => 'http://riddl.org/ns/common-patterns/properties/1.0' }

      if property.nil?
        if doc.root.find("p:#{key}").any?
          @status = 500
          return # don't misuse post
        end
        doc.root.add newstuff.root
        res = XML::Smart::open(schema).transform_with(XML::Smart::open(Riddl::Utils::Properties::PROPERTIES_SCHEMA_XSL_RNG))
        if !doc.validate_against(XML::Smart::string(res))
          @status = 400
          return # bad request
        end
      else
        node = doc.root.find("p:#{property}")
        if node.any?
          if node.first.find("p:#{key}").any?
            @status = 500
            return # don't misuse post
          end
        else
          @status = 404
          return # this property does not exist
        end
      end
    end  

    # everything is fine, now do it
    XML::Smart::modify(properties) do |doc|
      doc.namespaces = { 'p' => 'http://riddl.org/ns/common-patterns/properties/1.0' }
      node = property.nil? ? doc.root : doc.find("/p:properties/p:#{property}").first
      node.add newstuff.root
    end
    return Riddl::Parameter::Simple.new("key",key)
  end  
  
end
