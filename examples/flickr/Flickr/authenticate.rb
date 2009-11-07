#!/usr/bin/ruby
require 'digest/md5'
require '../../lib/ruby/client'
require 'pp'

### init Riddl client and get resource
flickr = Riddl::Client.interface("http://api.flickr.com/services","flickr.xml")
rest = flickr.resource("/services/rest")

### read application key/secret
key = File.read('flickr.key').strip
secret = File.read('flickr.secret').strip

### get frob
if File.exists?('flickr.frob')
  frob = File.read('flickr.frob').strip
else  
  method = 'flickr.auth.getFrob'
  sig = Digest::MD5.hexdigest("#{secret}api_key#{key}method#{method}")
  status, res = rest.get [
    Riddl::Parameter::Simple.new("method",method,:query),
    Riddl::Parameter::Simple.new("api_key",key,:query),
    Riddl::Parameter::Simple.new("api_sig",sig,:query)
  ]
  raise "no valid frob" unless status == 200
  frob = XML::Smart::string(res[0].value.read).find('string(/rsp/frob)')
  File.open('flickr.frob','w'){|f|f.write(frob)}
end  

### prepare auth link
method = 'flickr.auth.getFrob'
perms = 'write'
sig = Digest::MD5.hexdigest("#{secret}api_key#{key}frob#{frob}perms#{perms}")
puts "Url to allow access for the client:"
puts "http://flickr.com/services/auth/?api_key=#{key}&perms=#{perms}&frob=#{frob}&api_sig=#{sig}"
