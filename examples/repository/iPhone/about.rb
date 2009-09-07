class About < Riddl::Implementation
  include MarkUSModule

  def response
    if File.exist?("about.html") == false
      puts "Can not read about.html"
      @status = 410 # 410: Gone
      return
    end
    Riddl::Parameter::Complex.new("about","text/html") do
      mystring = ''
      File.open("about.html", "r") { |f|
        mystring = f.read
      }
      mystring
    end
  end
end
