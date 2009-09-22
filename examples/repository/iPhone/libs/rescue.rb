class RESCUE < Riddl::Implementation
  include MarkUSModule

  def response

    client = Riddl::Client.new("http://sumatra.pri.univie.ac.at:9290/").resource("groups/" + @r[2...5].join("/"))
    status, res = client.request "get" => []
    if status != "200"
      message = "An error occurde on resource: groups/#{@r[2...5].join("/")}"
      p message
      return Show.new().showPage("Error: ReceivingFeed", message, status)
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
        status, res = client = Riddl::Client.new("http://sumatra.pri.univie.ac.at:9290/").resource("groups/" + @r[2...5].join("/")+"/count")
        count = res[0].value
        feed.find("//atom:entry").each do |e|
          id = e.find("string(atom:id)")
          if letter != id[0,1]
            letter = id[0,1]
            li_ letter.capitalize, :class => "sep"
          end
          li_ :style=>"vertical-align: middle" do
            table_ :style=>"width: 100%;" do 
              tr_ do 
                td_ :style=>"width:100%;" do 
                  a_ id, :href => "/#{@r.join("/")}/#{id}", :style=>"display:block; " 
                end 
                td_ :style => "vertical-align:middle;" do 
                  a_ :href=>"#confirm" + Digest::MD5.hexdigest(@r.join("/")+"/"+id), :class=>"slideup" do 
                    img_ :src=>"../js/custom/plusButton.png"
                  end
                end
                td_ do
                  small_ count, :class=>"counter"
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
        p_ "Do you want to add the resoure '#{id}' to your wallet?", :class=>"infoText"
        a_ "Yes", :onclick=>"addToWallet('#{@r[2...5].join("/")}/#{id}', 'wallet')", :class=>"greenButton goback"
        a_ "Cancel", :href=>"#", :class=>"redButton goback"
      end
    end
    html
  end
 
  def generateDetails( details )
    div_ :id => 'rescue' do
      name = details.find("string(details/vendor/name)")
      street = details.find("string(details/vendor/adress/street)")
      houseno = details.find("string(details/vendor/adress/housenumber)")
      zip = details.find("string(details/vendor/adress/ZIP)")
      city = details.find("string(details/vendor/adress/city)")
      state = details.find("string(details/vendor/adress/state)")
      phone = details.find("string(details/vendor/phone)")
      mail = details.find("string(details/vendor/mail)")
      uri = details.find("string(details/service/URI)")

      div_ :class => "toolbar" do
        h1_ name
        a_ "Back", :class => "back button", :href => "#"
      end
      div_ :class => "contact", :align=>"center" do
        p_ "Contact", :class=>"head"
        div_ :class=>"address" do
          p_ do b_ name end
          p_ street + " " + houseno
          p_ zip + " " + city
          p_ state
        end
        br_
        table_ :class=>"address", :style=>"text-align: left; margin: 0.5cm" do
          tr_ do
            td_ "Phone:"
            td_ do a_ phone, :href => "tel:#{phone}" end
          end
          tr_ do
            td_ "@Mail:"
            td_ do a_ mail, :href => "mailto:#{mail}" end
          end
          tr_ do
            td_ "WWW:"
            td_ do a_ uri, :href => uri end
          end
        end
      end
    end
  end
end

