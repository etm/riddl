#!/usr/bin/ruby
require '../../lib/ruby/client'
require 'pp'

### http://term.ie/oauth/example/index.php

oauth = Riddl::Client.interface("http://term.ie/","oauth.xml")

### http://term.ie/oauth/example/request_token.php
resource = oauth.resource("/oauth/example/request_token.php")
params = [ 
  Riddl::Option.new(:key,'key'),
  Riddl::Option.new(:secret,'secret'),
  Riddl::Option.new(:realm,'')
]
puts resource.simulate_post(params).read

status, response, headers = resource.post params
puts response.oauth_token
puts response.oauth_token_secret
