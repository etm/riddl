#!/usr/bin/ruby
require '../../lib/ruby/riddl/client'
require 'pp'

library = Riddl::Client.new("http://demo.wst.univie.ac.at/services/delay.php")
status, res = library.post [
  Riddl::Parameter::Simple.new("delay","10"),
]
id = res[0].value
p id

1.upto 10 do
  status, res = library.resource("/#{id}").get
  pp status
  pp res[0]
  sleep 1
end
