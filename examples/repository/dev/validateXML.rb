#!/usr/bin/ruby

include XML/Smart

xmlString = File.open("../details_master.xml", "r").read()

puts xmlString

x = XML::Smart.string(xmlString)
y = x.validate_against(XML::Smart::open("../rngs/details-of-service.rng")) 

puts y



