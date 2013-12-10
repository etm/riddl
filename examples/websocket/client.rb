require File.expand_path(File.dirname(__FILE__) + '/../../lib/ruby/riddl/client')

ep = Riddl::Client.interface('http://localhost:9292/',File.dirname(__FILE__) + '/description.xml')

test = ep.resource('/')

test.ws do |conn|
  conn.callback do
    ### called on connection
    conn.send_msg "Hello world"
    conn.send_msg "done"
  end

  conn.errback do |e|
    ### called on error
    puts "Got error: #{e}"
  end

  conn.stream do |msg|
    ### called when server responds
    puts "<#{msg}>"
    if msg.data == "done"
      conn.close_connection
    end
  end

  conn.disconnect do
    ### called on disconnect
    puts "gone"
    EM::stop_event_loop
  end
end
