class DisposeQuery < Riddl::Implementation
  include MarkUSModule

  def response
pp @p
    resource = @p[0].value.split("/")
pp resource
    client = Riddl::Client.new("http://sumatra.pri.univie.ac.at:9290/").resource("groups/" + resource[0])
    status, qi = client.request :get => [Riddl::Parameter::Simple.new("queryInput", "")]
pp qi[0].value.read
pp status
    status, prop = client.request :get => [Riddl::Parameter::Simple.new("propererties", "")]
pp prop[0].value.read
pp status
  end
end
