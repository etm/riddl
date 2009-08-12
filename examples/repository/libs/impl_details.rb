class DetailsGET < Riddl::Implementation
  include MarkUSModule

  def response
    if File.exist?("repository/#{@r[0]}/#{@r[1]}/#{@r[2]}/#{@r.last}/details.xml") == false
      puts "Can not read detials.xml from repository/#{@r[0]}/#{@r[1]}/#{@r[2]}/#{@r.last}"
      @status = 410 # 410: Gone
      return
    end
    Riddl::Parameter::Complex.new("list-of-services","text/xml") do
      mystring = ''
      File.open("repository/#{@r[0]}/#{@r[1]}/#{@r[2]}/#{@r.last}/details.xml", "r") { |f|
        mystring = f.read
      }
      mystring
    end
  end
end
