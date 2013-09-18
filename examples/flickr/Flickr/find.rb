#!/usr/bin/ruby
require 'digest/md5'
require '../../../lib/ruby/riddl/client'
require 'pp'

# no ready for use
unless File.exists?('flickr.frob')
  puts "Check the README file and use authenticate.rb."
  exit
end

puts "Let's go!!!"

### init Riddl client and get resource
flickr = Riddl::Client.interface("http://api.flickr.com/services","flickr.xml")

puts "Get resources!!!"

### get resources
rest = flickr.resource("/rest")

### read application key/secret/frob
key = File.read('flickr.key').strip
secret = File.read('flickr.secret').strip
frob = File.read('flickr.frob').strip

### get 
if File.exists?('flickr.token')
  token = File.read('flickr.token').strip
else 
  puts "hmm, there is no token...." 
  method = 'flickr.auth.getToken'
  sig = Digest::MD5.hexdigest("#{secret}api_key#{key}frob#{frob}method#{method}")
  status, res = rest.request :get => [
    Riddl::Parameter::Simple.new("method",method,:query),
    Riddl::Parameter::Simple.new("api_key",key,:query),
    Riddl::Parameter::Simple.new("frob",frob,:query),
    Riddl::Parameter::Simple.new("api_sig",sig,:query)
  ]
  raise "frob no longer valid, delete flickr.frob then retry authenticate.rb" unless status == 200
  token = XML::Smart::string(res[0].value.read).find('string(/rsp/auth/token)')

  puts res[0].value.read

  File.open('flickr.token','w'){|f|f.write(token)}
end

# check token
method = 'flickr.auth.checkToken'
sig = Digest::MD5.hexdigest("#{secret}api_key#{key}auth_token#{token}method#{method}")
status, res = rest.get [
  Riddl::Parameter::Simple.new("method",method,:query),
  Riddl::Parameter::Simple.new("api_key",key,:query),
  Riddl::Parameter::Simple.new("auth_token",token,:query),
  Riddl::Parameter::Simple.new("api_sig",sig,:query)
]
raise "token no longer valid, delete flickr.token, flickr.frob then retry authenticate.rb, flickr.rb" unless status == 200

method = 'flickr.people.findByEmail'
email = 'mcsorex@yahoo.com'

status, res, headers = rest.get [
  Riddl::Parameter::Simple.new("method",method,:query),
  Riddl::Parameter::Simple.new("api_key",key,:query),
  Riddl::Parameter::Simple.new("find_email",email,:query)
]
raise "token no longer valid, delete flickr.token, flickr.frob then retry authenticate.rb, flickr.rb" unless status == 200

puts "STATUS: #{status} RES:" + res[0].value.read + " HEADERS: #{headers}" 
