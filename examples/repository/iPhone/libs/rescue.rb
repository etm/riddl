class RESCUE < Riddl::Implementation
  include MarkUSModule

  def response
    client = Riddl::Client.new("http://sumatra.pri.univie.ac.at:9290/").resource("groups/" + @r[2...5].join("/"))
    status, res = client.request "get" => []
    if status != "200"
      p "An error occurde on resource: groups/#{@r[2...5].join("/")}"
      return Riddl::Parameter::Complex.new("feed","text/html") do "An error (No. #{status}) occurde on resource: groups/#{@r[2...5].join("/")}" end
    end

    html = div_(:id => 'rescue') do
      div_ :class => "toolbar" do
        h1_ @r.last
        a_ "Back", :class => "back button", :href => "#"
      end
      ul_ do
        pp "URI: Rescource: #{@r.join("/")}"
        XML::Smart::string(res[0].value.read).find("//entry").each do |e|
          id = e.find("string(id)")
          link = e.find("string(link)")
          li_ :class => "arrow" do
            a_ id, :href => "123/#{@r[1...4].join("/")}/#{id}"
          end
        end  
      end
    end
    Riddl::Parameter::Complex.new("div","text/html",html)
  end
end
