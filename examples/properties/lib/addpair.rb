class AddPair < Riddl::Implementation

  def response
    properties = @a[0]
    schema = @a[1]
    property = @p.detect{|p| p.name == 'key'}.value
    value = @p.detect{|p| p.name == 'value'}.value

    success = false
    newstuff = XML::Smart.string("<#{property} xmlns=\"http://riddl.org/ns/common-patterns/properties/1.0\">#{value}</#{property}>")
    XML::Smart::open(properties) do |doc|
      doc.namespaces = { 'p' => 'http://riddl.org/ns/common-patterns/properties/1.0' }
      doc.root.find("p:#{property}").delete_all!
      doc.root.add newstuff.root
      success = doc.validate_against(XML::Smart::open(schema))
    end  
    if success
      XML::Smart::modify(properties) do |doc|
        doc.namespaces = { 'p' => 'http://riddl.org/ns/common-patterns/properties/1.0' }
        doc.root.find("p:#{property}").delete_all!
        doc.root.add newstuff.root
      end
      return Riddl::Parameter::Simple.new("key",property)
    end  
    @status = 404
  end  
  
end
