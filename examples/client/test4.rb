#!/usr/bin/ruby
require '../../lib/ruby/riddl/client'
#require 'riddl/client'
require 'pp'

uri = 'http://Default%20User:robotics@localhost:8080/rw/rapid/execution?action=stop'

s = Time.now
library = Riddl::Client.new(uri)
status, res = library.post [
  Riddl::Parameter::Simple.new('action','stop')
]
p status
puts res[0].value.read unless res.empty?
puts Time.now-s

