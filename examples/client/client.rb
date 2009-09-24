#!/usr/bin/ruby
require '../../lib/ruby/client'
require 'pp'

library = Riddl::Client.new("http://localhost/serversimple_test.php")
books = library.resource("/")
status, res = books.request :get => [
  Riddl::Header.new("Library",7),
  Riddl::Parameter::Simple.new("author","mangler"),
  Riddl::Parameter::Simple.new("title","12")
]
p status
pp res
