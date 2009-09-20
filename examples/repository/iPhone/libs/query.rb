class ExecuteQuery < Riddl::Implementation
  include MarkUSModule

  def response
    # Get the queryInput of the group from selected resource
    resource = nil
    if @p[0].name == "selectedResource"
      resource = @p[0].value.split("/")
    else
      message = "The prameter 'selectedResource' is not given. Execution of the query is ompossible."
      p message
      return Show.new().showPage("Error: ExecuteQuery", message, status)
    end
    client = Riddl::Client.new("http://sumatra.pri.univie.ac.at:9290/").resource("groups/" + resource[0])
    status, res = client.request :get => [Riddl::Parameter::Simple.new("queryInput", "")]
    if status != "200"
      message = "Can not receive groups queryInput of " + resource[0]
      p message
      return Show.new().showPage("Error: ExecuteQuery", message, status)
    end
    
    # Read params according to queryInput
    qi = Hash.new()
    rng = XML::Smart::string(res[0].value.read)
    rng.namespaces = {"rng" => "http://relaxng.org/ns/structure/1.0"}
    elements = rng.find("//rng:define/rng:element/@name")
    elements.each do |e|
      @p.each do |p|
        qi[p.name] = p.value if p.name == e.value
      end
    end

    # Validate if params of request fit to queryInputSchema
    xml = "<queryInputMessage>\n<entry>"
    qi.each_pair {|key, value| xml += "<#{key}>#{value}</#{key}>\n" }
    xml += "</entry></queryInputMessage>\n"
    if XML::Smart::string(xml).validate_against(rng) == false
      message = "Some parameters in queryInput maybe wrong or may have an illegal value"
      p message
      return Show.new().showPage("Error: Parameter validation", message)
    end

    # Generate RIDDL input Parameters-Array
    riddlParams = Array.new();   
    qi.each_pair {|key, value| riddlParams << Riddl::Parameter::Simple.new(key, value) }

    # Get all services within the selected resource
    services = Array.new()
    getServices("http://sumatra.pri.univie.ac.at:9290/groups/", resource.join("/"), services)

    # Get queryOuput schema
    status, res = client.request :get => [Riddl::Parameter::Simple.new("queryOutput", "")]
    if status != "200"
      message = "Can not receive groups queryOutput of " + resource[0]
      p message
      return Show.new().showPage("Error: ExecuteQuery", message, status)
    end
    
    # Read params according to queryOutput
    qo = Array.new()
    rng = XML::Smart::string(res[0].value.read)
    rng.namespaces = {"rng" => "http://relaxng.org/ns/structure/1.0"}
    elements = rng.find("//rng:define/rng:element/@name")
    elements.each do |e|
      qo << e.value
    end

    # Execute request for services and generate HTML respond
    Riddl::Parameter::Complex.new("html","text/html") do
      div_ :id => 'query', :class => "metal" do
        div_ :class => "toolbar" do
          h1_ "Query Results"
          a_ "Back", :class => "back button", :href => "#"
        end
        ul_ do
          services.each do |s|
            li_ s['id'], :class => "head", :style=>"background-color:#e1e1e1; font-size:16px;"
            # Query service
            p "Query serivce at: #{s['link']}"
            service = Riddl::Client.new(s['link']).resource("")
            begin
              status, out = service.request :get => riddlParams
            rescue
              status = "Server not found"
            end
            if status != "200"
              li_ "Service '#{s['link']}' did not respond. Statuscode: #{status}", :style=>"font-size:14px; color: red;"
            else 
              xml = XML::Smart::string(out[0].value.read)
              li_ do
                if xml.validate_against(rng) == false
                  span_ "Service responded wrong queryOutputMessage"
                else
                  table_ :style=>"widht: 100%; font-size:14px;" do
                    xml.find("//entry").each do |e|
                      qo.each_with_index do |p, index|
                        tr_ do
                          td_ p
                          td_ "&nbsp;" * 5
                          td_ e.children[index].to_s
                        end
                      end
                      tr_ do td_ :colspan=>"3" do hr_ end end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
  
  def getServices( link, resource, services )
    client = Riddl::Client.new(link).resource(resource)
    status, res = client.request :get => []
    xml = XML::Smart::string(res[0].value.read)
    if res[0].name == "list-of-subgroups"
      xml.namespaces = {"atom" => "http://www.w3.org/2005/atom"}
      xml.find("//atom:entry/atom:id").each do |id|
        getServices(link, resource+"/"+id.text, services)
      end
    elsif res[0].name == "list-of-services"
      xml.namespaces = {"atom" => "http://www.w3.org/2005/atom"}
      xml.find("//atom:entry").each do |e|
        link = ""
        id = ""
        e.children.each do |c|
          id = c.text if c.name.name  == "id" 
          link = c.text if c.name.name  == "link" 
        end
        services <<  {'id'=>resource+"/"+id, 'link'=>link}
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
      form_ :method=>"GET", :action=>"query", :id=>"queryForm" do
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
        tr_ do td_ do input_ :style=>"font-size: 24px;", :type=>"text", :name=>name, :id=>"input_"+name, :value=>"1212-12-12" end end
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

