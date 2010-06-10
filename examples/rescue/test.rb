require '../../lib/ruby/client.rb'
require 'rubygems'
require 'xml/smart'

      endpoint = "http://scn.hollywood-megaplex.at/sinemaweb/service.asmx"
      client = Riddl::Client.new(endpoint)
      parameters = Hash.new
      parameters[:parameters] = [{"SearchItem"=>"Avatar"}]
      parameters[:soap_operation] = "FilmInfo"
      status, resp = client.get [Riddl::Parameter::Simple.new("WSDL",nil,:query)]
      raise "Endpoint #{endpoint} doesn't provide a WSDL" if status != 200
      wsdl = XML::Smart.string(resp[0].value.read)
      msg = wsdl.find("//wsdl:portType/wsdl:operation[@name = '#{parameters[:soap_operation]}']/wsdl:input/@mesage", {"wsdl"=>"http://schemas.xmlsoap.org/wsdl/"}).first
      envelope = XML::Smart.string("<SOAP-ENV:Envelope xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\"/>")
      envelope.root.attributes['xmlns:ns1'] = wsdl.root.attributes['targetNamespace']
      body = envelope.root.add("body")
      body.name.namespace = "http://schemas.xmlsoap.org/soap/envelope/"
      soap_params = body.add("#{parameters[:soap_operation]}")
      soap_params.name.namespace = wsdl.root.attributes['targetNamespace']
      parameters[:parameters].each do |hash|
        hash.each do |k,v|
          soap_params.add("ns1:#{k}",v)
        end
      end
      puts envelope.to_s
      status, result = client.post [Riddl::Parameter::Complex.new("", "text/xml", envelope.to_s)]
      puts result[0].value.read
