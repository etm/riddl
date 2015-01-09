#!/usr/bin/ruby
require 'pp'
require File.expand_path(File.dirname(__FILE__) + '/../../lib/ruby/riddl/server')

class Bar < Riddl::Implementation
  def response  
    Riddl::Parameter::Complex.new("return","text/plain","hello world")
  end  
end

$socket = []

class Echo < Riddl::WebSocketImplementation
  def onopen
    $socket << self
    puts "Connection established"
  end

  def onmessage(data)
    printf("Received: %p\n", data)
    send data
    printf("Sent: %p\n", data)
  end

  def onclose
    $socket.delete(self)
    puts "Connection closed"
  end
end

Thread.new do
  i = 1
  while true
    $socket.each do |sock|
      sock.send("oasch #{i}")
    end
    i+=1
    sleep 2
  end
end

Riddl::Server.new(File.dirname(__FILE__) + '/description.xml', :port => 9292) do
  cross_site_xhr true

  on resource do
    run Bar if get '*'
    run Echo if websocket
  end
end.loop!
