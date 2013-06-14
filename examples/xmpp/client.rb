#!/usr/bin/ruby
# encoding: UTF-8
require '../../lib/ruby/client'
require 'pp'

#props = Riddl::Client.new("http://localhost:9292")
props = Riddl::Client.new("xmpp://adventure_processexecution@fp7-adventure.eu", nil, :jid => 'jürgen@fp7-adventure.eu', :pass => 'mangler', :debug => STDOUT)

test = props.resource("/values/state")
status, res = test.get
puts status
p '---------'

if res[0].value == 'running'
  status, res = test.put [ Riddl::Parameter::Simple.new("value","stopped") ]
else  
  status, res = test.put [ Riddl::Parameter::Simple.new("value","running") ]
end

puts status
