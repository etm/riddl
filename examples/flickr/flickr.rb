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
  raise "frob no longer valid, delete flickr.frob then retry authenticate.rb" unless status == 200
  token = XML::Smart::string(res[0].value.read).find('string(/rsp/auth/token)')
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

# upload image
title = "RIDDL Logo"
desc = "The official RIDDL logo, the first thing created for this project."
tags = "RIDDL, REST, Composition, Evolution"
is_public = "1"
sig = Digest::MD5.hexdigest("#{secret}api_key#{key}auth_token#{token}description#{desc}is_public#{is_public}tags#{tags}title#{title}")
status, res = upload.post [
  Riddl::Parameter::Simple.new("api_key", key),
  Riddl::Parameter::Simple.new("auth_token", token),
  Riddl::Parameter::Complex.new("photo","image/png",File.open('riddl.png','r'),'riddl.png'),
  Riddl::Parameter::Simple.new("title", title),
  Riddl::Parameter::Simple.new("description", desc),
  Riddl::Parameter::Simple.new("tags", tags),
  Riddl::Parameter::Simple.new("is_public", is_public),
  Riddl::Parameter::Simple.new("api_sig", sig)
]  

rsp = XML::Smart::string(res[0].value.read)
stat = rsp.find('string(/rsp/@stat)')
if stat == 'ok'
  puts "Status:  " + stat
  puts "PhotoID: " + rsp.find('string(/rsp/photoid)')
else
  puts "Status:  " + stat
  puts "Reason: --------------------------------------"
  puts rsp.to_s
end
