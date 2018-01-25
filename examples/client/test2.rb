#!/usr/bin/ruby
require '../../lib/ruby/riddl/client'
require 'pp'

uri = 'https://mangler:test@httpbin.org/digest-auth/auth/mangler/test/MD5/never'

library = Riddl::Client.new(uri)
status, res = library.get

p status
