#!/usr/bin/ruby
require '../../lib/ruby/riddl/client'
require 'pp'

twitter = Riddl::Client.interface("https://api.twitter.com/","twitter.xml")

### Base
consumer_key      = File.read(File.expand_path(File.dirname(__FILE__) + '/.twitter.consumer_key')).strip
consumer_secret   = File.read(File.expand_path(File.dirname(__FILE__) + '/.twitter.consumer_secret')).strip
file_user_id      = File.expand_path(File.dirname(__FILE__) + '/.twitter.user_id')
file_token        = File.expand_path(File.dirname(__FILE__) + '/.twitter.token')
file_token_secret = File.expand_path(File.dirname(__FILE__) + '/.twitter.token_secret')

### When token and secret already saved, skip this part
if !File.exists?(file_token) && !File.exists?(file_token_secret)
  ### go to request token resource and set necessary role options
  resource = twitter.resource("/oauth/request_token")
  params = [ 
    Riddl::Option.new(:consumer_key,consumer_key),
    Riddl::Option.new(:consumer_secret,consumer_secret)
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
    Riddl::Option.new(:token_secret,token_secret)
  ]
  user_id = response.user_id
  token = response.oauth_token
  token_secret = response.oauth_token_secret

  File.open(file_user_id,'w'){|f|f.write response.oauth_token}
  File.open(file_token,'w'){|f|f.write response.oauth_token}
  File.open(file_token_secret,'w'){|f|f.write response.oauth_token_secret}
else
  user_id = File.read(file_user_id).strip
  token = File.read(file_token).strip
  token_secret = File.read(file_token_secret).strip
end

### Show single tweet
#tweet = 258251258941554688 # some stuff
#status, res = twitter.resource("/1.1/statuses/show.json").get [
#    Riddl::Parameter::Simple.new("id",tweet),
#    Riddl::Option.new(:consumer_key,consumer_key),
#    Riddl::Option.new(:consumer_secret,consumer_secret),
#    Riddl::Option.new(:token,token),
#    Riddl::Option.new(:token_secret,token_secret)
#]
#puts status

### Show timeline
#status, res = twitter.resource("/1.1/statuses/user_timeline.json").get [
#    Riddl::Option.new(:consumer_key,consumer_key),
#    Riddl::Option.new(:consumer_secret,consumer_secret),
#    Riddl::Option.new(:token,token),
#    Riddl::Option.new(:token_secret,token_secret)
#]
#puts status

### Status update
if ARGV.length >= 1
  ### Update status
  status, res = twitter.resource("/1.1/statuses/update.json").post [
    Riddl::Parameter::Simple.new("status",ARGV.join(' ')),
    Riddl::Option.new(:consumer_key,consumer_key),
    Riddl::Option.new(:consumer_secret,consumer_secret),
    Riddl::Option.new(:token,token),
    Riddl::Option.new(:token_secret,token_secret)
  ]
  puts "something went wrong!" if status != 200
else  
  puts "Usage: #{__FILE__} [TWEET]"
end
