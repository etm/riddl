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
realm = 'Riddl Client'

### request token
resource = twitter.resource("/oauth/request_token")
params = [ 
  Riddl::Option.new(:key,'key'),
  Riddl::Option.new(:secret,'secret'),
  Riddl::Option.new(:realm,'')
]
puts resource.simulate_post(params).read

status, response, headers = resource.post params
puts response.oauth_token
puts response.oauth_token_secret

### Show single tweet
# status, res = twitter.resource("/statuses/show/#{tweet}.xml").get
# p status
# puts res[0].value.read

### Update status
#status, res = twitter.resource("/statuses/update.xml").post [
#  Riddl::Header.new("Authorization","Basic #{cred}"),
#  Riddl::Parameter::Simple.new("status","It's a Riddl.")
#]
