#!/usr/bin/ruby
require 'riddl/lib/ruby/client'
require 'pp'
require 'rubygems'
require 'cgi'
require 'time'
require 'base64'
require 'openssl'
require 'digest/md5'
require 'digest/sha1'
require 'digest/sha2'
require 'libxml' 

ACCESS_IDENTIFIER = 'WKy3rMzOWPouVOxK1p3Ar1C2uRBwa2FBXnCw'
SECRET_IDENTIFIER = 'GSh8NRa1XHRt9TA4IC2nvg8ByKSu7eOkA'
AMAZON_ENDPOINT = 'http://192.168.232.128:8773/services'

t = Time.now

hour_str = t.strftime("%H")
hour = hour_str.to_i
hour -= 1

time_formated = t.strftime("%a, %d %b %Y ") + hour.to_s + t.strftime(":%M:%S +0000")

string_to_sign="GET\n\n\n#{time_formated}\n/services/Walrus"

digest = OpenSSL::Digest::Digest.new('sha1')

hmac = OpenSSL::HMAC.digest(digest, SECRET_IDENTIFIER, string_to_sign)
signature = Base64.encode64(hmac)

amazon = Riddl::Client.interface("#{AMAZON_ENDPOINT}","S3.xml")
rest = amazon.resource("/Walrus")

status, res, headers = rest.get [
  Riddl::Header.new("Date","#{time_formated}"),
  Riddl::Header.new("Authorization","#{ACCESS_IDENTIFIER}:#{signature}"),
  Riddl::Header.new("content-type","")
]

puts "STATUS: #{status}\n" 

raise "error" unless status == 200

puts "HEADER:" + headers.inspect + "\n"

xml = ""

xml << res[0].value.read

document = LibXML::XML::Document.string(xml)
document.save("xml_temp.txt")
IO.foreach("xml_temp.txt"){|block| puts block}
