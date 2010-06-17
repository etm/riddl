require '../../lib/ruby/client.rb'
require 'rubygems'
require 'xml/smart'

      endpoint = "http://www.kinoimkesselhaus.at/programm/programm-kino"
      client = Riddl::Client.new(endpoint)
      status, resp = client.get
      puts status
      puts resp.inspect
      puts resp.value('').read
