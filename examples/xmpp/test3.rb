# encoding: UTF-8
require 'rubygems'
require 'securerandom'
require 'pp'
require 'blather/client/client'

EM.run do

  client = Blather::Client.setup "jürgen@fp7-adventure.eu", 'mangler'

  client.register_handler(:ready) { puts "Connected ! send messages to #{client.jid.stripped}." }

  client.register_handler :message, :chat? do |m|
    client.write Blather::Stanza::Message.new(m.from, 'Exiting...')
  end

  client.connect

end
