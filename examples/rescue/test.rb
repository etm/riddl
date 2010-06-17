require '../../lib/ruby/client.rb'
require 'rubygems'
require 'xml/smart'
require 'cgi'

      endpoint = "http://www.cineplexx.at/content/kinos/kinos_programme.aspx"
      client = Riddl::Client.new(endpoint)
      status, resp = client.get [Riddl::Parameter::Simple.new("id", 6)]
      puts status
      puts resp.inspect
      str = CGI::unescapeHTML(resp.value('').read)
      str.gsub!('&', '&amp;')
      xml = XML::Smart.string(str)
      puts xml
