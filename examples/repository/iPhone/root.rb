class GetJS < Riddl::Implementation
  include MarkUSModule

  def response
    p "Requesting JS #{$r[2]}"
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

class GetTheme < Riddl::Implementation
  include MarkUSModule

  def response
    p "Requesting Theme #{$r[2]}"
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
    p "Requesting Image #{$r[2]}"
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
