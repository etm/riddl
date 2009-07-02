class DetailsGET < Riddl::Implementation
  include MarkUSModule


  def response
    Riddl::Parameter::Complex.new("list-of-services","text/xml") do
        File.open("repository/#{@r[0]}/#{@r[1]}/#{@r[2]}/#{@r.last}/details.xml")
    end
  end
end
