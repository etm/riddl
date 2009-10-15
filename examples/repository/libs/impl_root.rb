class RootGET < Riddl::Implementation
  include MarkUSModule

  def response
    if File.exist?("description.xml") == false
      puts "Can not read description.xml"
      @status = 410 # 410: Gone
      return
    end
    Riddl::Parameter::Complex.new("description","text/xml", File.open("description.xml", "r"))
  end
end

class WhiteInformationGET < Riddl::Implementation
  include MarkUSModule

  def response
    if File.exist?("rngs/details-of-service.rng") == false
      puts "Can not read rngs/details-of-service.rng"
      @status = 410 # 410: Gone
      return
    end
    Riddl::Parameter::Complex.new("whiteInformation-response","text/xml", File.open("rngs/details-of-service.rng", "r"))
  end
end
