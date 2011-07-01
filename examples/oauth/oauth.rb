#!/usr/bin/ruby
require '../../lib/ruby/client'
require '../../lib/ruby/client/oauth'
require 'pp'

### http://term.ie/oauth/example/index.php

oauth = Riddl::Client.new("http://term.ie/")
# oauth = Riddl::Client.interface("http://term.ie/","oauth.xml")

### http://term.ie/oauth/example/request_token.php
key = 'key'
secret = 'secret'
realm = ''

### request token
resource = oauth.resource("/oauth/example/request_token.php")
params = [ ]
Riddl::Client::OAuth::request_token(resource,params,realm,key,secret)

puts resource.simulate_post(params.dup).read

status, result = resource.post params

puts result[0].value.read
