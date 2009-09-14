class RESCUE < Riddl::Implementation
  include MarkUSModule

  def response
pp @e
    client = Riddl::Client.new("http://sumatra.pri.univie.ac.at:9290/").resource("groups/" + @r[1..5].join("/"))
    status, res = client.request "get" => []
    if status != "200"
      p "An error occurde on resource: groups/#{@r[1...5].join("/")}"
      return Riddl::Parameter::Complex.new("feed","text/html") do "An error (No. #{status}) occurde on resource: groups/#{@r[1...5].join("/")}" end
    end

    html = div_(:id => 'rescue') do
      div_ :class => "toolbar" do
        h1_ @r.last
        a_ "Back", :class => "back button", :href => "#"
      end
      ul_ do
        pp "URI: Rescource: groups/#{@r[1..5].join("/")}"
        feed = XML::Smart::string(res[0].value.read)
        feed.namespaces = {"atom" => "http://www.w3.org/2005/atom"}
        feed.find("//atom:entry").each do |e|
          id = e.find("string(atom:id)")
#          link = e.find("string(atom:link)")
          li_ :class => "arrow" do
pp "#{@r[0...4].join("/")}/#{id}"
            a_ id, :href => "#{@r[0...4].join("/")}/#{id}"
#            a_ id, :href => "#{id}"
          end
        end  
      end
    end
    Riddl::Parameter::Complex.new("div","text/html",html)
  end
end
