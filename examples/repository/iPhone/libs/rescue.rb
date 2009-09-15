class RESCUE < Riddl::Implementation
  include MarkUSModule

  def response

    client = Riddl::Client.new("http://sumatra.pri.univie.ac.at:9290/").resource("groups/" + @r[1...4].join("/"))
    status, res = client.request "get" => []
    if status != "200"
      p "An error occurde on resource: groups/#{@r[1...4].join("/")}"
      return Riddl::Parameter::Complex.new("feed","text/html") do "An error (No. #{status}) occurde on resource: groups/#{@r[1...4].join("/")}" end
    end

    html = ""
    xml = XML::Smart::string(res[0].value.read)
    if @r.size <= 3 #Groups or Subgrops
      html = generateList(xml)
    end
    if @r.size == 4 # Servicedetails
      html = generateDetails(xml)
    end
    Riddl::Parameter::Complex.new("div","text/html",html)
  end

  def generateList( feed )
    div_ :id => 'rescue', :class => "edgetoedge" do
      div_ :class => "toolbar" do
        h1_ @r.last.capitalize
        a_ "Back", :class => "back button", :href => "#"
      end
      ul_ do
        feed.namespaces = {"atom" => "http://www.w3.org/2005/atom"}
        letter = ""
        feed.find("//atom:entry").each do |e|
          id = e.find("string(atom:id)")
          if letter != id[0,1]
            letter = id[0,1]
            li_ letter.capitalize, :class => "head"
          end
          li_ do
# 123 needs to be changed to be dynamic
            form_ :id=>"ajax_post", :action=>"123/wallet", :method=>"POST", :class=>"form" do
              a_ id.capitalize, :href => "/#{@r.join("/")}/#{id}"
              input_ :hidden=>"text", :name=>"resource", :value=>@r.join("/")+"/"+id
              input_ :type=>"submit"
              a_ "Add to wallet", :style=>"margin:0 10px;color:rgba(0,0,0,.9); size", :href=>"#", :class=>"submit whiteButton"
            end
          end
        end  
      end
    end
  end

  def generateDetails( details )
    details.namespaces = {"d" => "http://rescue.org/servicedetails"}
    div_ :id => 'rescue' do
      name = details.find("d:details/d:vendor/text()").first.to_s
      street = details.find("/d:details/d:adress/d:street/text()").first.to_s
      houseno = details.find("/d:details/d:adress/d:housenumber/text()").first.to_s
      zip = details.find("/d:details/d:adress/d:ZIP/text()").first.to_s
      city = details.find("/d:details/d:adress/d:city/text()").first.to_s
      state = details.find("/d:details/d:adress/d:state/text()").first.to_s
      phone = details.find("/d:details/d:phone/text()").first.to_s
      mail = details.find("/d:details/d:mail/text()").first.to_s
      uri = details.find("/d:details/d:URI/text()").first.to_s

      div_ :class => "toolbar" do
        h1_ name
        a_ "Back", :class => "back button", :href => "#"
      end
      div_ :class => "contact", :align=>"center" do
        br_
        br_
        h3_ "Contact", :style=>"font-size: 24pt; color: #FFFFFF"
        br_
        div_ :style=>"font-size: 18px" do
          span_ do b_ name end
          br_
          span_ street + " " + houseno
          br_
          span_ zip + " " + city
          br_
          span_ state
        end
        br_
        br_
        table_ :style=>"font-size: 18px" do
          tr_ do
            td_ "Phone:"
            td_ do a_ phone, :href => "tel:#{phone}" end
          end
          tr_ do
            td_ "@Mail:"
            td_ do a_ mail, :href => "mailto:#{mail}" end
          end
          tr_ do
            td_ "URI:"
            td_ do a_ uri, :href => uri end
          end
        end
      end
    end
  end
end

