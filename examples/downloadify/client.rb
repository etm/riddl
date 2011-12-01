#!/usr/bin/ruby
require '../../lib/ruby/client'
require 'pp'

srv = Riddl::Client.interface("http://localhost:9299","server.declaration.xml")

status, ret = srv.resource('/test.txt').post [
  Riddl::Parameter::Simple.new("mimetype","text/plain"),
  Riddl::Parameter::Simple.new("content","Hello World")
]

p status
p ret
