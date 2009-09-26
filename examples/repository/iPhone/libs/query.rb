class ExecuteQuery < Riddl::Implementation
  include MarkUSModule

  def response
    # Get the queryInput of the group from selected resource
    resource = nil
    if @p[0].name == "selectedResource"
      resource = @p[0].value.split("/")
    else
      message = "The parameter 'selectedResource' is not given. Execution of the query is impossible."
      p message
      return Show.new().showPage("Error: ExecuteQuery", message)
    end
    client = Riddl::Client.new("http://sumatra.pri.univie.ac.at:9290").resource("/groups/" + resource[0])
    begin
      status, res = client.request :get => [Riddl::Parameter::Simple.new("queryInput", "")]
    rescue
      message = "Server (http://sumatra.pri.univie.ac.at:9290) refused connection on resource: /" + resource.join("/") + "?queryInput"
      p message
      return Show.new().showPage("Error: Connection refused", message, status, true)
    end

    if status != "200"
      message = "Can not receive groups queryInput of " + resource[0]
      p message
      return Show.new().showPage("Error: ExecuteQuery", message, status)
    end
    
    # Read params according to queryInput and RIDDL-them into riddlParams
    riddlParams = Array.new();   
    rng = XML::Smart::string(res[0].value.read)
    rng.namespaces = {"rng" => "http://relaxng.org/ns/structure/1.0"}
    elements = rng.find("//rng:define/rng:element/@name")
    xml = "<queryInputMessage>\n\t<entry>\n"
    elements.each do |e|
      @p.each do |p|
        if p.name == e.value
          xml += "\t\t<#{p.name}>#{p.value}</#{p.name}>\n"
          riddlParams << Riddl::Parameter::Simple.new(p.name, p.value)
        end
      end
    end
    xml += "\t</entry>\n</queryInputMessage>\n"

    # Validate if params of request fit to queryInputSchema
    if XML::Smart::string(xml).validate_against(rng) == false
      message = "Some parameters have an illegal value"
      p message
      return Show.new().showPage("Error: Parameter validation", message)
    end

    # Get all services within the selected resource
    services = Array.new()
    getServices("http://sumatra.pri.univie.ac.at:9290/groups/", resource.join("/"), services)

    # Get queryOuput schema
    begin
      status, res = client.request :get => [Riddl::Parameter::Simple.new("queryOutput", "")]
    rescue
      message = "Server (http://sumatra.pri.univie.ac.at:9290) refused connection on resource: /" + resource.join("/") + "?queryOutput"
      p message
      return Show.new().showPage("Error: Connection refused", message, status, true)
    end

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
        ul_ :id=>"queryResultsList", :class=>"metal" do
          li_ "No services found in the given resource" if services.size == 0
          services.each do |s|

            # Header for Service
            li_ :class=>"sep" do 
              p_ s['id'], :style=>"text-overflow:ellipsis;overflow:hidden;max-width:260px;"
            end
            # Query service
            p "Query serivce #{s['id']} at: #{s['link']}"
            service = Riddl::Client.new(s['link']).resource("")
            begin
              status, out = service.request :get => riddlParams
            rescue
              message = "Server (http://sumatra.pri.univie.ac.at:9290) refused connection on resource: /" + resource.join("/") + riddlParams.join(", ")
              p message
              return Show.new().showPage("Error: Connection refused", message, status, true)
            end
            if status != "200"
              li_ "Service '#{s['id']}' did not respond. Statuscode: #{status}", :class=>"errorText"
            else 
              xml = XML::Smart::string(out[0].value.read)
              if xml.validate_against(rng) == false
                li_ do
                  span_ "Service responded wrong queryOutputMessage"
                end
              else 
                xml.find("//entry").each do |e|
                  li_ do
                    # Reslutset
                    table_ :class=>"result" do
                      qo.each_with_index do |p, index|
                        tr_ do
                          td_ p
                          td_ "&nbsp;" * 5
                          td_ e.children[index].to_s
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
  end
  
  def getServices( link, resource, services )
    client = Riddl::Client.new(link).resource('/'+resource)
    begin
      status, res = client.request :get => []
    rescue
      message = "Server (#{link}) refused connection on resource: " + resource
      p message
      return Show.new().showPage("Error: Connection refused", message, status, true)
    end

    xml = XML::Smart::string(res[0].value.read)
    if res[0].name == "list-of-subgroups" || res[0].name == "list-of-services"
      xml.namespaces = {"atom" => "http://www.w3.org/2005/atom"}
      xml.find("//atom:entry/atom:id").each do |id|
        getServices(link, resource+"/"+id.text, services)
      end
    elsif res[0].name == "details-of-service"
      link = xml.find("string(//service/URI)")
      name = xml.find("string(//vendor/name)")
      services <<  {'id'=>name+' ('+resource+')', 'link'=>link}
    else
      message = "Illegeal paramter responded named " + res[0].name
      p message
      return Show.new().showPage("Error: Collecting sub-resource", message, status)
    end
  end
end



class DisposeQuery < Riddl::Implementation
  include MarkUSModule

  def response
    # Get the properties of the group from selected resource
puts "Generating form"
    resource = @p[0].value.split("/")
    client = Riddl::Client.new("http://sumatra.pri.univie.ac.at:9290").resource("/groups/" + resource[0])
    begin
      status, prop = client.request :get => [Riddl::Parameter::Simple.new("properties", "")]
    rescue
      message = "Server (#{link}) refused connection on resource: groups/" + resource[0]
      p message
      return Show.new().showPage("Error: Connection refused", message, status, true)
    end

    if status != "200"
      mesage = "Can not receive groups properties of " + resource[0]
      p message
      return Show.new().showPage("Error: DisposeQuery", message, status)
    end

    Riddl::Parameter::Complex.new("html","text/html") do
      arrayString = "new Array('selectedResource',"
#      form_ :method=>"GET", :action=>"query", :id=>"queryForm" do
        div_ :id=>"disposeQueryForm" do
          p_ "Enter query parameter for resource: #{@p[0].value}", :class=>"infoText"
          input_ :type=>"hidden", :value=>@p[0].value, :name=>"input_selectedResource", :id=>"input_selectedResource"
          table_ do
            xml = XML::Smart::string(prop[0].value.read)
            qi = xml.find("/properties/dynamic/queryInput/*/@name")
            qi.each do |e|
              createInput(e.value, xml)
              arrayString += "'#{e.value}',"
            end
          end
        end
        arrayString = arrayString.chop + ")"
        a_ "Query", :onClick=>"getQueryResult(#{arrayString})", :href=>"#queryResult", :class=>"greenButton slideup", :id=>"queryButton"
#      end
    end
  end

  def createInput(name, xml)
    label =  xml.find("string(/properties/dynamic/queryInput/element[@name='#{name}']/caption[@lang='en'])")
    type =  xml.find("string(/properties/dynamic/queryInput/element[@name='#{name}']/data/@type)")
    minS = ""
    maxS = ""
    if type.downcase.include? "integer"
      minS = xml.find("string(/properties/dynamic/queryInput/element[@name='#{name}']/data/param[@name='minInclusive'])")
      maxS = xml.find("string(/properties/dynamic/queryInput/element[@name='#{name}']/data/param[@name='maxInclusive'])")
    end
    tr_ do 
      tr_ do td_ :class=>"formLabel" do label + ": " end end
      # Found number input with given range
      if minS != "" && maxS != ""
        min = minS.to_i
        max = maxS.to_i
        tr_ do td_ do
          select_ :class=>"formLabel", :name=>name, :id=>"input_"+name do
            while min <= max do
              option_ min
              min = min+1
            end
          end
        end end
      # Found date
      elsif type.downcase.include? "date"
      # Found string or number without any pecification
        tr_ do td_ do
          select_ :class=>"formLabel", :name=>name, :id=>"input_"+name do
            today = Date.today();
            i=0
            while i <= 356 do
             xD = (today+i)
             option_ "#{Date::ABBR_DAYNAMES[xD.wday()]}, %02d. #{Date::ABBR_MONTHNAMES[xD.month()]} #{xD.year()}" % xD.day(), :value=>(today+i).to_s, :class=>"formLabel"
              i = i+1
            end
          end
        end end
      
      else
        tr_ do td_ do input_ :style=>"", :type=>"text", :name=>name, :id=>"input_"+name, :class=>"formLabel" end end
      end
    end
  end
end

