#!/usr/bin/ruby
require '../../lib/ruby/client'
require 'Helpers/flickr.rb'
require 'pp'
  
fh = FlickrHelper.new("Flickr/")
params = [ 
  Riddl::Parameter::Simple.new("api_key", fh.api_key),
  Riddl::Parameter::Simple.new("auth_token", fh.auth_token),
  Riddl::Parameter::Complex.new("photo","image/jpeg",File.open('riddl.jpg','r'),'riddl.jpg'),
  Riddl::Parameter::Simple.new("author", "Jürgen Mangler"),
  Riddl::Parameter::Simple.new("title", "RIDDL Logo"),
  Riddl::Parameter::Simple.new("description", "The official RIDDL logo, the first thing created for this project."),
  Riddl::Parameter::Simple.new("tags", "RIDDL, REST, Composition, Evolution"),
  Riddl::Parameter::Simple.new("longitude", 48.213736),
  Riddl::Parameter::Simple.new("latitude", 16.357141),
  Riddl::Parameter::Simple.new("is_public", 1),
]
params <<  Riddl::Parameter::Simple.new("api_sig", fh.sign(params,["api_key","auth_token","title","description","tags","is_public"]))

dflick = Riddl::Client.facade("declaration.xml")
upload = dflick.resource("/upload")
status, res = upload.post params

puts status
puts res[0].value.read
