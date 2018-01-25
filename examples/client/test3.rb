#!/usr/bin/ruby
require '../../lib/ruby/riddl/client'
#require 'riddl/client'
require 'pp'

uri = 'http://gruppe.wst.univie.ac.at/~mangler/services/oebb.php?_taetigkeiten=taetigkeiten.txt&strategie=IS1&_schaedigungen=schaedigungen.txt'

s = Time.now
library = Riddl::Client.new(uri)
status, res = library.post [
  Riddl::Parameter::Simple.new("delay","10")
]
p status
puts res[0].value.read
puts Time.now-s

