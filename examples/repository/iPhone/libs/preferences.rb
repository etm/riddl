class PreferencesValue < Riddl::Implementation
  include MarkUSModule

  def response
    xml = XML::Smart::open("user/#{@r[0]}/preferences.xml")
    Riddl::Parameter::Simple.new('preferences-value', xml.find("string(/#{@r[1...10].join('/')})"))
  end
end

class PreferencesForm < Riddl::Implementation
  include MarkUSModule

  def response
=begin
    rng = XML::Smart::open("rngs/preferences.rng")
    xml = XML::Smart::open("user/#{@r[0]}/preferences.xml")
    lang = xml.find("string(/preferences/general/lang)")
    Riddl::Parameter::Complex.new('html','text/html') do
      div_ do
        rng.find("/rng:grammar/rng:start/rng:element/*", 
                {"rng" => "http://relaxng.org/ns/structure/1.0"}).each do |group|
          ul_ do
            li_ getCaption(lang, group), :class=>"sep"
x = "/rng:grammar/rng:start/rng:element[@name=\"#{group.attributes['name']}\"]/rng:element"
puts x
            rng.find(x, 
                    {"rng" => "http://relaxng.org/ns/structure/1.0"}).each do |element|

puts "JUCHU"
              puts element.attributes['name']
              li_ getCaption(lang, element)
            end
          end
        end
      end
    end
=end
  end

  def getCaption(lang, element)
    element.children.each do |child|
      if child.name.to_s == "ui:caption"
        if child.attributes['lang'] == lang
          return child.text
        end
      end
    end
  end

end
