class RootGET < Riddl::Implementation
  include MarkUSModule

  def response
    if File.exist?("description.xml") == false
      puts "Can not read description.xml"
      @status = 410 # 410: Gone
      return
    end
    Riddl::Parameter::Complex.new("description","text/xml") do
      mystring = ''
      File.open("description.xml", "r") { |f|
        mystring = f.read
      }
      mystring
    end
  end
end
