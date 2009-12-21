class Keys < Riddl::Implementation

  def response
    properties = @a[0]
    schema = @a[1]

    XML::Smart::open(schema) do |doc|
      doc.namespaces = { 'p' => 'http://riddl.org/ns/common-patterns/properties/1.0' }
      ret = XML::Smart.string("<keys xmlns=\"http://riddl.org/ns/common-patterns/properties/1.0\"/>")
      doc.find("/p:properties/*[name()!='optional']|/p:properties/p:optional/*").each do |r|
        ret.root.add("key",r.name.to_s)
      end
      return Riddl::Parameter::Complex.new("keys","text/xml",ret.to_s)
    end
  end

end
