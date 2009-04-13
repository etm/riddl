#!/usr/bin/ruby
require 'net/http'
require 'rubygems'
require 'multipart'
require 'pp'

url = URI.parse('http://localhost:9292/')
req = Net::HTTP::Post.new(url.path)

file1 = Net::HTTP::FileForPost.new('description.xml', 'text/xml')
file2 = Net::HTTP::FileForPost.new('declaration.xml', 'text/xml')
req.set_multipart_data(
  { 
    :description => file1,
    :declaration => file2
  },
  {
    :author => 'eTM',
    :user_agent => 'riddler'
  }
)

res = Net::HTTP.new(url.host, url.port).start do |http|
  http.request(req)
end
