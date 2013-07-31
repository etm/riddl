#!/usr/bin/ruby
# encoding: UTF-8
require '../../lib/ruby/client'
require 'pp'

#props = Riddl::Client.interface("http://localhost:9191","properties.xml")
props = Riddl::Client.interface("xmpp://adventure_processexecution@fp7-adventure.eu", "properties.xml", :jid => 'jürgen@fp7-adventure.eu', :pass => 'mangler', :debug => STDOUT)

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
