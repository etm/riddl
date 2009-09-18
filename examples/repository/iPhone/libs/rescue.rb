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
    html = div_ :id => 'rescue', :class => "edgetoedge" do
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
            li_ letter.capitalize, :class => "head", :style=>"background-color:#e1e1e1;"
          end
          li_ :style=>"vertical-align: middle" do
            table_ :style=>"width: 100%;" do 
              tr_ do 
                td_ :style=>"width:100%;" do 
                  a_ id.capitalize, :href => "/#{@r.join("/")}/#{id}", :style=>"display:block; " 
                end 
                td_ :style => "vertical-align:middle;"do 
                  a_ :href=>"#confirm" + Digest::MD5.hexdigest(@r.join("/")+"/"+id), :class=>"slideup" do 
                    img_ :src=>"../js/custom/plusButton.png"
                  end
                end
              end
            end
          end
        end  
      end
    end
    # Parse feed a second time and generate confirm-div's
    feed.find("//atom:entry").each do |e|
      id = e.find("string(atom:id)")
      html += div_ :id=>"confirm" + Digest::MD5.hexdigest(@r.join("/")+"/"+id) do
        div_ :class => "toolbar" do
          h1_ "Confirm"
        end
        br_
        br_
        h4_ "Do you want to add the resoure '#{id}' to your wallet?", :style=>"font-size: 20pt; text-align:center;"
        br_
        br_
        a_ "Yes", :style=>"margin:0 10px;color:green", :onclick=>"addToWallet('#{@r[2...5].join("/")}/#{id}', 'wallet')", :class=>"whiteButton goback"
        br_
        a_ "Cancel", :style=>"margin:0 10px;color:red", :href=>"#", :class=>"whiteButton goback"
      end
    end
    html
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

