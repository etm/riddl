#!/usr/bin/ruby
require 'digest/md5'
require '../../lib/ruby/client'
require 'pp'

# no ready for use
unless File.exists?('flickr.frob')
  puts "Check the README file and use authenticate.rb."
  exit
end

### init Riddl client and get resource
flickr = Riddl::Client.interface("http://api.flickr.com/","flickr.xml")
rest = flickr.resource("/services/rest")

### get resources
rest = flickr.resource("/services/rest")
upload = flickr.resource("/services/upload")

### read application key/secret/frob
key = File.read('flickr.key').strip
secret = File.read('flickr.secret').strip
frob = File.read('flickr.frob').strip

### get 
if File.exists?('flickr.token')
  token = File.read('flickr.token').strip
else  
  method = 'flickr.auth.getToken'
  sig = Digest::MD5.hexdigest("#{secret}api_key#{key}frob#{frob}method#{method}")
  status, res = rest.get [
    Riddl::Parameter::Simple.new("method",method,:query),
    Riddl::Parameter::Simple.new("api_key",key,:query),
    Riddl::Parameter::Simple.new("frob",frob,:query),
    Riddl::Parameter::Simple.new("api_sig",sig,:query)
  ]
  raise "no valid token" unless status == 200
  token = XML::Smart::string(res[0].value.read).find('string(/rsp/auth/token)')
  File.open('flickr.token','w'){|f|f.write(token)}
end
