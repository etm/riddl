#!/usr/bin/ruby
require '../../lib/ruby/client'
require '../../lib/ruby/utils/oauth'
require 'pp'

tweet = 4997095028 # eTM
user = 10154142 # eTM
cred = "xxxxxx"
twitter = Riddl::Client.interface("https://twitter.com/","twitter.xml")

### OAUTH Base
# key = "JUGRfvAcSIjxpJ13g96Fw"
# secret = "fTV93ULm4PtKGTZL2YGE22vvwuwidDl9RdBkZC15Y"
# realm = 'Riddl Client'

### http://term.ie/oauth/example/request_token.php


### request token
resource = twitter.resource("/oauth/request_token")
params = [ ]
Riddl::Utils::OAuth::request_token(resource,params,realm,key,secret)

# sim = resource.simulate_post params
# puts sim.read

p "----------"

status, resource = resource.post params
pp resource[0].value.read

### Show single tweet
# status, res = twitter.resource("/statuses/show/#{tweet}.xml").get
# p status
# puts res[0].value.read

### Update status
#status, res = twitter.resource("/statuses/update.xml").post [
#  Riddl::Header.new("Authorization","Basic #{cred}"),
#  Riddl::Parameter::Simple.new("status","It's a Riddl.")
#]
