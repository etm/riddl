class ExecuteQuery < Riddl::Implementation
  include MarkUSModule

  def response
    qiParams = Array.new()
    resource = nil
    # Get the queryInput of the group from selected resource
    if @p[0].name == "selectedResource"
      resource = @p[0].value.split("/")
    else
      message = "The prameter 'selectedResource' is not given. Execution of the query is ompossible."
      p message
      return Show.new().showPage("Error: ExecuteQuery", message, status)
    end
    client = Riddl::Client.new("http://sumatra.pri.univie.ac.at:9290/").resource("groups/" + resource[0])
    status, qiRes = client.request :get => [Riddl::Parameter::Simple.new("queryInput", "")]
    if status != "200"
      message = "Can not receive groups queryInput of " + resource[0]
      p message
      return Show.new().showPage("Error: ExecuteQuery", message, status)
    end
    
    # Read params according to queryInput
    rng = XML::Smart::string(qiRes[0].value.read)
    rng.namespaces = {"rng" => "http://relaxng.org/ns/structure/1.0"}
    elements = rng.find("//rng:element[@name='queryInputMessage']/rng:element/@name")
    elements.each do |e|
      @p.each do |p|
        qiParams << {'name' =>  p.name, 'value' => p.value} if p.name == e.value
      end
    end

    # Validate if params of request fit to queryInputSchema
    xml = "<queryInputMessage>\n"
    qiParams.each do |p|
      xml += "<#{p['name']}>#{p['value']}</#{p['name']}>"
    end
    xml += "</queryInputMessage>\n"
    if XML::Smart::string(xml).validate_against(rng) == false
      message = "Some parameters in queryInput maybe wrong or may have an illegal value"
      p message
      return Show.new().showPage("Error: Parameter validation", message)
    end

    # Get all services within the selected resource
    services = Array.new()
    getServices("http://sumatra.pri.univie.ac.at:9290/groups/"+resource.join("/"), services)
pp services
    # Execute request for services

    # Generate HTML respond
=begin    Riddl::Parameter::Complex.new("html","text/html") do
"bla"
    end
=end
  end
  
  def getServices( link, services )
    client = Riddl::Client.new(link).resource("")
    status, res = client.request :get => []
    xml = XML::Smart::string(res[0].value.read)
    if res[0].name == "list-of-subgroups"
      xml.namespaces = {"atom" => "http://www.w3.org/2005/atom"}
      xml.find("//atom:entry/atom:link").each do |link|
        getServices(link.text, services)
      end
    elsif res[0].name == "list-of-services"
      xml.namespaces = {"atom" => "http://www.w3.org/2005/atom"}
      xml.find("//atom:entry/atom:link").each do |link|
        services <<  link.text
# Thinking: Will the name of the service or URi will be helpfull for later use?
      end
    else
      message = "Illigeal paramter responded named " + res[0].name
      p message
      return Show.new().showPage("Error: Collecting sub-rescource", message, status)
    end
  end
end



class DisposeQuery < Riddl::Implementation
  include MarkUSModule

  def response
    # Get the properties of the group from selected resource
    resource = @p[0].value.split("/")
    client = Riddl::Client.new("http://sumatra.pri.univie.ac.at:9290/").resource("groups/" + resource[0])
    status, res = client.request :get => [Riddl::Parameter::Simple.new("properties", "")]
    if status != "200"
      mesage = "Can not receive groups properties of " + resource[0]
      p message
      return Show.new().showPage("Error: DisposeQuery", message, status)
    end

    Riddl::Parameter::Complex.new("html","text/html") do
      arrayString = "new Array('selectedResource',"
      form_ :method=>"GET", :action=>"query" do
        div_ :class => "toolbar" do
          h1_ "Resource query"
          a_ "Back", :class => "back button", :href => "#"
        end
        div_ :id=>"query" do
          input_ :type=>"text", :value=>@p[0].value, :name=>"input_selectedResource", :id=>"input_selectedResource"
          table_ :style=>"" do
            xml = XML::Smart::string(res[0].value.read)
            qi = xml.find("/properties/dynamic/queryInput/*/@name")
            qi.each do |e|
              createInput(e.value, xml)
              arrayString += "'#{e.value}',"
            end
          end
          arrayString = arrayString.chop + ")"
          a_ "Query", :style=>"margin:0 10px;color:green", :class=>"whiteButton", :onClick=>"getQueryResult(#{arrayString})"
        end
      end
    end
  end

  def createInput(name, xml)
    label =  xml.find("string(/properties/dynamic/queryInput/element[@name='#{name}']/caption[@lang='en'])")
    type =  xml.find("string(/properties/dynamic/queryInput/element[@name='#{name}']/data/@type)")
    min = ""
    max = ""
    if type.downcase.include? "integer"
      minS = xml.find("string(/properties/dynamic/queryInput/element[@name='#{name}']/data/param[@name='minInclusive'])")
      maxS = xml.find("string(/properties/dynamic/queryInput/element[@name='#{name}']/data/param[@name='maxInclusive'])")
    end
    tr_ do 
      tr_ do td_ :style=>"font-size: 24pt;" do label + ": " end end
      if minS == nil && maxS == nil
        tr_ do td_ do input_ :style=>"font-size: 24px;", :type=>"text", :name=>name, :id=>"input_"+name end end
      else
        min = minS.to_i
        max = maxS.to_i
        tr_ do td_ do
          select_ :style=>"font-size: 24px;", :name=>name, :id=>"input_"+name do
            while min <= max do
              option_ min
              min = min+1
            end
          end
        end end
      end
    end
  end
end

