class GetJS < Riddl::Implementation
  include MarkUSModule

  def response
    if File.exist?("js/#{@r.last}") == false
      puts "Can not read #{@r.last}"
      @status = 410 # 410: Gone
      return
    end

    Riddl::Parameter::Complex.new("java-script","application/x-javascript", File.open("js/#{@r.last}", "r"))
  end
end

class GetTheme < Riddl::Implementation
  include MarkUSModule

  def response
    p "Requesting Theme #{@r[2]}"
    puts $r
    Riddl::Parameter::Complex.new("about","text/html") do
      mystring = ''
      File.open("about.html", "r") { |f|
        mystring = f.read
      }
      mystring
    end
  end
end

class GetImage < Riddl::Implementation
  include MarkUSModule

  def response
    p "Requesting Image #{@r[2]}"
    Riddl::Parameter::Complex.new("img","image/png", File.open("themes/img/#{@r[2]}", "r"))
  end
end
