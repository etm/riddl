#!/usr/bin/ruby
require '../../lib/ruby/riddl/client'
#require 'riddl/client'
require 'pp'

uri = 'http://Default%20User:robotics@localhost:8080/rw/rapid/execution?action=start'

s = Time.now
library = Riddl::Client.new(uri)
status, res = library.post [
  Riddl::Parameter::Simple.new('regain','continue'),
  Riddl::Parameter::Simple.new('execmode','continue'),
  Riddl::Parameter::Simple.new('cycle','once'),
  Riddl::Parameter::Simple.new('condition','none'),
  Riddl::Parameter::Simple.new('stopatbp','disabled'),
  Riddl::Parameter::Simple.new('alltaskbytsp',false)
]
p status
puts res
puts Time.now-s

