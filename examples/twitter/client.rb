#!/usr/bin/ruby
require '../../lib/ruby/client'
require 'pp'

tweet = 4997095028 # eTM
user = 10154142 # eTM
cred = "xxxxxx"
twitter = Riddl::Client.interface("https://twitter.com/","twitter.xml")

### Base
consumer_key = 'JUGRfvAcSIjxpJ13g96Fw'
consumer_secret = 'fTV93ULm4PtKGTZL2YGE22vvwuwidDl9RdBkZC15Y'
realm = 'Riddl Client'
file_token = File.expand_path(File.dirname(__FILE__) + '/twitter.token')
file_token_secret = File.expand_path(File.dirname(__FILE__) + '/twitter.token_secret')

### When token and secret already saved, skip this part
if !File.exists?(file_token) && !File.exists?(file_token_secret)
  ### go to request token resource and set necessary role options
  resource = twitter.resource("/oauth/request_token")
  params = [ 
    Riddl::Option.new(:consumer_key,consumer_key),
    Riddl::Option.new(:consumer_secret,consumer_secret),
    Riddl::Option.new(:realm,realm)
  ]
  
  ### simulate request token
  # puts resource.simulate_post(params).read
  
  ### get request token and save it to variables
  status, response, headers = resource.post params
  token = response.oauth_token
  token_secret = response.oauth_token_secret
  
  ### send user away for authorization
  puts "Authorize at https://twitter.com/oauth/authorize?oauth_token=#{token}"
  print "Insert verifier here: "
  verifier = STDIN.gets.strip # wait for verifier
  
  ### exchange the token for an access token and save the results
  resource = twitter.resource("/oauth/access_token")
  status, response, headers = resource.post [ 
    Riddl::Option.new(:consumer_key,consumer_key),
    Riddl::Option.new(:consumer_secret,consumer_secret),
    Riddl::Option.new(:token,token),
    Riddl::Option.new(:verifier,verifier),
    Riddl::Option.new(:token_secret,token_secret),
    Riddl::Option.new(:realm,realm)
  ]
  user_id = response.user_id
  File.open(file_token,'w'){|f|f.write response.oauth_token}
  File.open(file_token_secret,'w'){|f|f.write response.oauth_token_secret}
end

### Show single tweet
status, res = twitter.resource("/statuses/show/#{tweet}.xml").get
puts res[0].value.read

### Update status
#status, res = twitter.resource("/statuses/update.xml").post [
#  Riddl::Header.new("Authorization","Basic #{cred}"),
#  Riddl::Parameter::Simple.new("status","It's a Riddl.")
#]
