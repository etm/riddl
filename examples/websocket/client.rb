#!/usr/bin/ruby
require File.join(__dir__, '../../lib/ruby/riddl/client')

ep = Riddl::Client.interface('http://localhost:9292/',File.join(__dir__,'/description.xml'))

test = ep.resource('/')

test.ws do |conn|
  conn.on :open do
    ### called on connection
    conn.send "Hello world"
    conn.send "done"
  end

  conn.on :error do |e|
    ### called on error
    puts "Got error: #{e}"
  end

  conn.on :message do |msg|
    ### called when server responds
    puts "<#{msg.data}>"
    if msg.data == "done"
      conn.close
    end
  end

  conn.on :close do
    ### called on disconnect
    puts "gone"
    EM::stop_event_loop
  end
end
