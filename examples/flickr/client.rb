#!/usr/bin/ruby
require '../../lib/ruby/client'
require 'pp'

tweet = 4997095028 # eTM
user = 10154142 # eTM
cred = "ZXRtOnR3aXR0ZXJ0d2l0dGVy"
twitter = Riddl::Client.interface("http://twitter.com/","twitter.xml")

### Show single tweet
# status, res = twitter.resource("/statuses/show/#{tweet}.xml").get
# p status
# puts res[0].value.read

### Update status
status, res = twitter.resource("/statuses/update.xml").post [
  Riddl::Header.new("Authorization","Basic #{cred}"),
  Riddl::Parameter::Simple.new("status","It's a Riddl.")
]
p status
puts res[0].value.read
