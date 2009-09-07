class About < Riddl::Implementation
  include MarkUSModule

  def response
    if File.exist?("html/about.html") == false
      puts "Can not read about.html"
      @status = 410 # 410: Gone
      return
    end
    Riddl::Parameter::Complex.new("about","text/html", File.open("html/about.html", "r"))
  end
end
