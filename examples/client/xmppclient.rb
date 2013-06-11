#!/usr/bin/ruby
# encoding: UTF-8
require '../../lib/ruby/client'
require 'pp'

library = Riddl::Client.new("xmpp://adventure_processexecution@fp7-adventure.eu/services/delay.php", nil, :jid => 'jürgen@fp7-adventure.eu', :pass => 'mangler')
status, res = library.post [
  Riddl::Header.new("delay","10"),
  Riddl::Parameter::Simple.new("delay","10"),
]

p status
p res
sleep 2
