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
    if @r.size <= 3 #Groups or Subgrops
      html = div_ :id => 'rescue', :class => "edgetoedge" do
        div_ :class => "toolbar" do
          h1_ @r.last.capitalize
          a_ "Back", :class => "back button", :href => "#"
        end
        ul_ do
          feed = XML::Smart::string(res[0].value.read)
          feed.namespaces = {"atom" => "http://www.w3.org/2005/atom"}
          letter = ""
          feed.find("//atom:entry").each do |e|
            id = e.find("string(atom:id)")
            if letter != id[0,1]
              letter = id[0,1]
              li_ letter.capitalize, :class => "head"
            end
            li_ do
              a_ id.capitalize, :href => "/#{@r.join("/")}/#{id}"
            end
          end  
        end
      end
    end
    if @r.size == 4 # Servicedetails
      html = div_ :id => 'rescue' do

        details = XML::Smart::string(res[0].value.read)
        details.namespaces = {"d" => "http://rescue.org/servicedetails"}

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
        table_  do
          tr_ do
            td_ :colspan => "2" do h4_ "Adress" end
          end
          tr_ do
            td_ street
            td_ houseno, :align=>"right"
          end
          tr_ do
            td_ zip
            td_ city
          end
          tr_ do
            td_ state, :colspan => "2"
          end
        end
        br_
        br_
        table_ do
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
    Riddl::Parameter::Complex.new("div","text/html",html)
  end
end

