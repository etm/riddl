class RESCUE < Riddl::Implementation
  include MarkUSModule

  def response

    client = Riddl::Client.new("http://sumatra.pri.univie.ac.at:9290").resource("/groups/" + @r[2...5].join("/"))
    begin
      status, res = client.request "get" => []
    rescue
      message = "Server (http://sumatra.pri.univie.ac.at:9290) refused connection on resource: /groups/#{@r[2...5].join("/")}"
      p message
      return Show.new().showPage("Error: Connection refused", message, status, true)
    end
    if status != "200"
      message = "An error occurde on resource: groups/#{@r[2...5].join("/")}"
      p message
      return Show.new().showPage("Error: RESCUE sever dis not respond as expected", message, status, true)
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
        a_ "Back", :class => "back goback", :href => "#"
        a_ "Main", :class=>"button goback", :id=>"infoButton", :href=>"#main"
      end
      ul_ do
        feed.namespaces = {"atom" => "http://www.w3.org/2005/atom"}
        letter = ""
        feed.find("//atom:entry").each do |e|
          id = e.find("string(atom:id)")
          client = Riddl::Client.new("http://sumatra.pri.univie.ac.at:9290").resource("/groups/" + @r[2...5].join("/")+"/#{id}/count")
          begin
            status, res =  client.request :get=>[]
          rescue
            message = "Server (http://sumatra.pri.univie.ac.at:9290) refused connection on resource: /groups/" + @r[2...5].join("/")+"/#{id}/count"
            p message
            return Show.new().showPage("Error: Connection refused", message, status, true)
          end

          count = res[0].value

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
                if @r.size < 4 && status == "200"
                  td_ do
                    small_ count, :class=>"counter", :style=>"margin: 0px 5px;"
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
      div_ :id=>"confirm" + Digest::MD5.hexdigest(@r.join("/")+"/"+id) do
        div_ :class => "toolbar" do
          h1_ "Confirm"
        end
        p_ "Do you want to add the resoure '#{id}' to your wallet?", :class=>"infoText"
        a_ "Yes", :onclick=>"addToWallet('#{@r[2...5].join("/")}/#{id}', 'wallet')", :class=>"greenButton goback"
        a_ "Cancel", :href=>"#", :class=>"redButton goback"
      end
    end
    __markus_return
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
        a_ "Main", :class=>"button goback", :id=>"infoButton", :href=>"#main"
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
            td_ :style=>"text-overflow:ellipsis;overflow:hidden;max-width:240px;" do a_ uri, :href => uri end
          end
        end
      end
    end
  end
end

