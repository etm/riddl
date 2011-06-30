#!/usr/bin/ruby
require '../../lib/ruby/client'
require 'pp'

tweet = 4997095028 # eTM
user = 10154142 # eTM
cred = "xxxxxx"
twitter = Riddl::Client.interface("https://twitter.com/","twitter.xml")

### OAUTH Base
key = "JUGRfvAcSIjxpJ13g96Fw"
secret = "fTV93ULm4PtKGTZL2YGE22vvwuwidDl9RdBkZC15Y"
timestamp = Time.now.to_i
nonce = "wIjqoS"

### request token
sim = twitter.resource("/oauth/request_token").simulate_post [
  Riddl::Header.new("Authorization","OAuth realm='Riddl Client'," +
    "oauth_consumer_key='#{key}'," +
    "oauth_signature_method='HMAC-SHA1'," +
    "oauth_timestamp='#{timestamp}'," +
    "oauth_nonce='#{nonce}'"
  ),
  Riddl::Parameter::Simple.new("status","aaabbbccc",:query)
]
puts sim.read.strip

### Show single tweet
# status, res = twitter.resource("/statuses/show/#{tweet}.xml").get
# p status
# puts res[0].value.read

### Update status
#status, res = twitter.resource("/statuses/update.xml").post [
#  Riddl::Header.new("Authorization","Basic #{cred}"),
#  Riddl::Parameter::Simple.new("status","It's a Riddl.")
#]
