require 'rexml/document'

class RESCUE < Riddl::Implementation
  include REXML

  def response
    client = Riddl::Client.new("http://sumatra.pri.univie.ac.at:9290/").resource("groups/" + @r[2...5].join("/"))
    status, res = client.request "get" => []
    if status != "200"
      p "An error occurde on resource: groups/#{@r[2...5].join("/")}"
      return Riddl::Parameter::Complex.new("feed","text/html") do "An error (No. #{status}) occurde on resource: groups/#{@r[2...5].join("/")}" end
    end
    html ="
           <div id=\"rescue\">
             <div class=\"toolbar\">
               <h1>#{@r.last}</h1>
                <a class=\"back button\" href=\"#\">Back</a>
             </div>
             <ul>"
pp "URI: Rescource: #{@r.join("/")}"
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
      html += "<li class=\"arrow\"><a href=\"123/#{@r[1...4].join("/")}/#{id}\">#{id}</a></li>\n"
    }
    html += "</ul>\n"
    html += "</div>\n"
    Riddl::Parameter::Complex.new("div","text/html") do
      html
    end
  end
end
