require 'rexml/document'

class RESCUE < Riddl::Implementation
  include REXML

  def response
    client = Riddl::Client.new("http://sumatra.pri.univie.ac.at:9290/").resource("groups/" + @r[2...5].join("/"))
    status, res = client.request "get" => []
    @status = status
    if status != "200"
      p "An error occurde on resource: groups/#{@r[2...5].join("/")}"
      return Riddl::Parameter::Complex.new("feed","text/html") do "An error (No. #{status}) occurde on resource: groups/#{@r[2...5].join("/")}" end
    end
    html = "<div id=\"#{@r[2...5].join("/")}\">\n"
    Document.new(res[0].value).elements.each("//entry") { |e| 
      id = ""
      link = ""
      e.elements.each() { |child| 
        if child.name == "id"
          id = child.text
        end
        if child.name == "link"
          link = child.text
        end
      }
      # Add the following line: <li><a href="#item1">Item 1</a></li>
      html += "\t<li><a href=\"#{link}\">#{id}</a></li>\n"
    }
    html += "</div>\n"
    ret = Riddl::Parameter::Complex.new("feed","text/html") do
      html
    end
pp ret
    # Riddl::Parameter::Simple.new("Test", "test_val", "string") 
    return ret
  end
end
