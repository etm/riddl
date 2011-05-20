#!/usr/bin/ruby
require 'pp'
require 'riddl/lib/ruby/client'
require 'rubygems'
require 'base64'
require 'openssl'
require 'digest/sha1'
require 'xml/smart' 


# als Klasse bauen, mit new


ACCESS_IDENTIFIER = 'WKy3rMzOWPouVOxK1p3Ar1C2uRBwa2FBXnCw'
SECRET_IDENTIFIER = 'GSh8NRa1XHRt9TA4IC2nvg8ByKSu7eOkA'
AMAZON_ENDPOINT = 'http://192.168.232.128:8773/services'

time_formated = Time.now.strftime('%a, %-d %b %Y %T %z')
string_to_sign = "GET\n\n\n#{time_formated}\n/services/Walrus"

digest = OpenSSL::Digest::Digest.new('sha1')
hmac = OpenSSL::HMAC.digest(digest, SECRET_IDENTIFIER, string_to_sign)
signature = Base64.encode64(hmac)

amazon = Riddl::Client.interface("#{AMAZON_ENDPOINT}","S3.xml")
rest = amazon.resource("/Walrus")

status, res, headers = rest.get [
  Riddl::Header.new("Date","#{time_formated}"),
  Riddl::Header.new("Authorization","#{ACCESS_IDENTIFIER}:#{signature}"),
  Riddl::Header.new("Content-Type","")
]

puts "STATUS: #{status}\n" 

exit unless status == 200

puts "HEADER:" + headers.inspect + "\n"
puts XML::Smart.string(res[0].value.read).to_s

