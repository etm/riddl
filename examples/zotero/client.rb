#!/usr/bin/ruby
require '../../lib/ruby/client'
require 'xml/smart'
require 'pp'

### Base
consumer_key      = File.read(File.expand_path(File.dirname(__FILE__) + '/zotero.consumer_key')).strip
consumer_secret   = File.read(File.expand_path(File.dirname(__FILE__) + '/zotero.consumer_secret')).strip
file_user_id      = File.expand_path(File.dirname(__FILE__) + '/zotero.user_id')
file_token        = File.expand_path(File.dirname(__FILE__) + '/zotero.token')
file_token_secret = File.expand_path(File.dirname(__FILE__) + '/zotero.token_secret') #}}}

### When token and secret already saved, skip this part #{{{
if !File.exists?(file_token) && !File.exists?(file_token_secret)
  zotero = Riddl::Client.interface("https://www.zotero.org/","zotero.xml")

  ### go to request token resource and set necessary role options
  resource = zotero.resource("/oauth/request")
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
  puts "Authorize at https://www.zotero.org/oauth/authorize?oauth_token=#{token}"
  print "Insert verifier here: "
  verifier = STDIN.gets.strip # wait for verifier
  
  ### exchange the token for an access token and save the results
  resource = zotero.resource("/oauth/access")
  status, response, headers = resource.post [ 
    Riddl::Option.new(:consumer_key,consumer_key),
    Riddl::Option.new(:consumer_secret,consumer_secret),
    Riddl::Option.new(:token,token),
    Riddl::Option.new(:verifier,verifier),
    Riddl::Option.new(:token_secret,token_secret)
  ]
  user_id = response.userID
  token = response.oauth_token
  token_secret = response.oauth_token_secret

  File.open(file_user_id,'w'){|f|f.write response.userID}
  File.open(file_token,'w'){|f|f.write response.oauth_token}
  File.open(file_token_secret,'w'){|f|f.write response.oauth_token_secret}
else
  user_id = File.read(file_user_id).strip
  token = File.read(file_token).strip
  token_secret = File.read(file_token_secret).strip
end #}}}

zotero = Riddl::Client.interface("https://api.zotero.org/","zotero.xml")
status, res = zotero.resource("/groups/62639/collections/X69MNMZX/collections").get [
  Riddl::Parameter::Simple.new('key',token,:query)
]
doc = XML::Smart.string(res.first.value.read)
doc.namespaces = { 'a' => 'http://www.w3.org/2005/Atom', 'z' => 'http://zotero.org/ns/api' }
keys = []
doc.find('//a:entry').each do |e|
  keys << e.find('string(z:key)')
end

keys.each do |k|
  status, res = zotero.resource("/groups/62639/collections/#{k}/items").get [
    Riddl::Parameter::Simple.new('key',token,:query)
  ]
  doc = XML::Smart.string(res.first.value.read)
  doc.namespaces = { 'a' => 'http://www.w3.org/2005/Atom', 'z' => 'http://zotero.org/ns/api' }
  doc.find('//a:entry/a:title').each do |e|
    puts e.to_s
  end
  p '-------'
end  

