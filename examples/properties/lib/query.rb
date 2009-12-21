class Query < Riddl::Implementation
  def response
    properties = @a[0]
    schema = @a[1]
    xml = File::read(properties).gsub(/properties xmlns="[^"]+"|properties xmlns='[^']+'/,'properties')
    e = XML::Smart::string(xml).root.find(@p[0].value)
    prop = XML::Smart::string("<value xmlns=\"http://riddl.org/ns/common-patterns/properties/1.0\"/>")
    if e.class == XML::Smart::Dom::NodeSet
      if e.any?
        t = e.first
        if t.find("*").any?
          prop.root.add(t.children)
        else  
          prop.root.text = t.to_s
        end  
      else
        XML::Smart::string("<not-existing xmlns=\"http://riddl.org/ns/common-patterns/properties/1.0\"/>")
      end
    else
      prop.root.text = e.to_s
    end
    return Riddl::Parameter::Complex.new("document","text/xml",prop.to_s)
  end  

end
