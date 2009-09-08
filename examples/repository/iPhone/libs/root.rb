class GetJS < Riddl::Implementation
  include MarkUSModule

  def response
    p "Requesting Java-Script js/#{@r.last}"
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
    p "Requesting Theme themes/#{@r.last}"
    if File.exist?("themes/#{@r.last}") == false
      puts "Can not read themes/#{@r.last}"
      @status = 410 # 410: Gone
      return
    end
    # File.open needs to be changed when recursive is implemented in riddl  (filename with dirs)
    Riddl::Parameter::Complex.new("css","text/css", File.open("themes/#{@r.last}", "r"))
  end
end

class GetImage < Riddl::Implementation
  include MarkUSModule

  def response
    p "Requesting Image themes/img/#{@r[2]}"
    if File.exist?("themes/img/#{@r[2]}") == false
      puts "Can not read themes/img/#{@r[2]}"
      @status = 410 # 410: Gone
      return
    end
    # File.open needs to be changed when recursive is implemented in riddl (filename with dirs)
    Riddl::Parameter::Complex.new("img","image/png", File.open("themes/img/#{@r[2]}", "r"))
  end
end
