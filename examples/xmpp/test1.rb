require 'rubygems'
require 'blather/client/dsl'
require 'pp'

module Ping
  extend Blather::DSL  

  when_ready { puts "Connected ! send messages to #{jid.inspect}." }

  handle :iq do |m|
    pp m
    pp "iq\n------------"
  end

  message do |m|
    pp m
    pp "message\n------------"
  end
end

jid = Blather::JID.new('adventure_processexecution', 'fp7-adventure.eu')
Ping.setup jid, 'adventure_processexecution'
EM.run { Ping.run }
