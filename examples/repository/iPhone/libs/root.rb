class GetJS < Riddl::Implementation
  include MarkUSModule

  def response
    if File.exist?("js/#{@r.last}") == false
      puts "Can not read #{@r.last}"
      @status = 410 # 410: Gone
      return
    end
    # File.open needs to be changed when recursive is implemented in riddl (filename with dirs)
    Riddl::Parameter::Complex.new("java-script","application/x-javascript", File.open("js/#{@r.last}", "r"))
  end
end

class GetTheme < Riddl::Implementation
  include MarkUSModule

  def response
    p "Requesting Theme #{@r.last}"
    # File.open needs to be changed when recursive is implemented in riddl  (filename with dirs)
    Riddl::Parameter::Complex.new("css","text/css", File.open("themes/#{@r.last}", "r"))
  end
end

class GetImage < Riddl::Implementation
  include MarkUSModule

  def response
    p "Requesting Image #{@r[2]}"
    # File.open needs to be changed when recursive is implemented in riddl (filename with dirs)
    Riddl::Parameter::Complex.new("img","image/png", File.open("themes/img/#{@r[2]}", "r"))
  end
end
