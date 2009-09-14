class RESCUE < Riddl::Implementation
  include MarkUSModule

  def response

    # This generation of the path seems to be necessary because jqTuche adds som elements to the URI itself
    path = Array.new()
    for i in 0..@r.size-1 do
      path << @r[i] if @r[i] != "rescue"
    end

    client = Riddl::Client.new("http://sumatra.pri.univie.ac.at:9290/").resource("groups/" + path.join("/"))
    status, res = client.request "get" => []
    if status != "200"
      p "An error occurde on resource: groups/#{path.join("/")}"
      return Riddl::Parameter::Complex.new("feed","text/html") do "An error (No. #{status}) occurde on resource: groups/#{path.join("/")}" end
    end

    html = div_ :id => 'rescue', :class => "edgetoedge" do
      div_ :class => "toolbar" do
        h1_ @r.last.capitalize
        a_ "Back", :class => "back button", :href => "#"
      end
      ul_ do
        pp "URI: Rescource: groups/#{path.join("/")}"
        feed = XML::Smart::string(res[0].value.read)
        feed.namespaces = {"atom" => "http://www.w3.org/2005/atom"}
        feed.find("//atom:entry").each do |e|
          id = e.find("string(atom:id)")
          li_ :class => "arrow" do
            a_ id.capitalize, :href => "rescue/#{path.join("/")}/#{id}"
          end
        end  
      end
    end
    Riddl::Parameter::Complex.new("div","text/html",html)
  end
end
