class Keys < Riddl::Implementation

  def response
    properties = @a[0]
    schema = @a[1]

    XML::Smart::open(schema) do |doc|
      doc.namespaces = { 'rng' => 'http://relaxng.org/ns/structure/1.0' }
      ret = XML::Smart.string("<keys xmlns=\"http://riddl.org/ns/common-patterns/properties/1.0\"/>")
      doc.find("/rng:element/rng:interleave/rng:element/@name|/rng:element/rng:interleave/rng:optional/rng:element/@name").each do |r|
        ret.root.add("key",r.to_s)
      end
      return Riddl::Parameter::Complex.new("keys","text/xml",ret.to_s)
    end
  end

end
