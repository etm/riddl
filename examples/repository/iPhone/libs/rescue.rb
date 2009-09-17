class RESCUE < Riddl::Implementation
  include MarkUSModule

  def response

    client = Riddl::Client.new("http://sumatra.pri.univie.ac.at:9290/").resource("groups/" + @r[2...5].join("/"))
    status, res = client.request "get" => []
    if status != "200"
      p "An error occurde on resource: groups/#{@r[2...5].join("/")}"
      return Riddl::Parameter::Complex.new("html","text/html") do "An error (No. #{status}) occurde on resource: groups/#{@r[2...5].join("/")}" end
    end

    html = ""
    xml = XML::Smart::string(res[0].value.read)
    if @r.size <= 4 #Groups or Subgrops
      html = generateList(xml)
    end
    if @r.size == 5 # Servicedetails
      html = generateDetails(xml)
    end
    Riddl::Parameter::Complex.new("hmtl","text/html",html)
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
            li_ letter.capitalize, :class => "head", :style=>"background-color:95A795;"
          end
          li_ :style=>"vertical-align: center" do
            img_ :src=>"../js/custom/plusButton.png", :onclick=>"addToWallet('#{@r[2...5].join("/")}/#{id}', 'wallet')"
            a_ id.capitalize, :href => "/#{@r.join("/")}/#{id}", :style => "display:inline; margin-left:10px;"
          end
        end  
      end
    end
  end
 
  def generateDetails( details )
    div_ :id => 'rescue' do
      name = details.find("string(details/vendor)")
      street = details.find("string(details/adress/street)")
      houseno = details.find("string(details/adress/housenumber)")
      zip = details.find("string(details/adress/ZIP)")
      city = details.find("string(details/adress/city)")
      state = details.find("string(details/adress/state)")
      phone = details.find("string(details/phone)")
      mail = details.find("string(details/mail)")
      uri = details.find("string(details/URI)")

      div_ :class => "toolbar" do
        h1_ name
        a_ "Back", :class => "back button", :href => "#"
      end
      div_ :class => "contact", :align=>"center" do
        br_
        br_
        h2_ "Contact", :style=>"font-size: 24pt;"
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

