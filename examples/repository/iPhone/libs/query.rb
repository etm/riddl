class ExecuteQuery < Riddl::Implementation
  include MarkUSModule

  def response
pp @p    
  end
end



class DisposeQuery < Riddl::Implementation
  include MarkUSModule

  def response
    resource = @p[0].value.split("/")
    client = Riddl::Client.new("http://sumatra.pri.univie.ac.at:9290/").resource("groups/" + resource[0])
    status, res = client.request :get => [Riddl::Parameter::Simple.new("properties", "")]
    if status != "200"
      p "Can not receive groups properties of " + resource[0]
      return Riddl::Parameter::Complex.new("html","text/html", showErrorPage(resource[0], status))
    end
    Riddl::Parameter::Complex.new("html","text/html") do
      form_ :method=>"GET", :action=>"query" do
        div_ :class => "toolbar" do
          h1_ "Resource query"
          a_ "Back", :class => "back button", :href => "#"
        end
        input_ :type=>"text", :value=>@p[0].value, :name=>"selectedResource"
        table_ :style=>"" do
          xml = XML::Smart::string(res[0].value.read)
          qi = xml.find("/properties/dynamic/queryInput/*/@name")
          qi.each do |e|
            createInput(e.value, xml)
          end
        end
        a_ "Query", :style=>"margin:0 10px;color:green", :class=>"whiteButton submit"
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
        tr_ do td_ do input_ :style=>"font-size: 24px;", :type=>"text", :name=>name, :id=>"some_name" end end
      else
        min = minS.to_i
        max = maxS.to_i
        tr_ do td_ do
          select_ :style=>"font-size: 24px;", :name=>name do
            while min <= max do
              option_ min
              min = min+1
            end
          end
        end end
      end
    end
  end

  def showErrorPage( resource, status )
    div_ :id => 'wallet' do  
      div_ :class => "toolbar" do
        h1_ "Resource query"
        a_ "Back", :class => "back button", :href => "#"
      end
      div_ :class => "message", :align=>"center" do
        br_
        br_
        h3_ "Can not receive properties of resource: " + resource + " Status: (" + status + ")", :style=>"font-size: 24pt;"
      end
    end
  end
end
