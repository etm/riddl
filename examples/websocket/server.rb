#!/usr/bin/ruby
require 'pp'
require File.expand_path(File.dirname(__FILE__) + '/../../lib/ruby/riddl/server')

class Bar < Riddl::Implementation
  def response
    Riddl::Parameter::Complex.new("return","text/plain","hello world")
  end
end

class Echo < Riddl::WebSocketImplementation
  def onopen
    puts "Connection established"
    Thread.new do
      1.upto 10 do |i|
        send("oasch #{i}")
        sleep 1
      end
      close
    end
  end

  def onmessage(data)
    printf("Received: %p\n", data)
    send data
    printf("Sent: %p\n", data)
  end

  def onclose
    puts "Connection closed"
  end
end

Riddl::Server.new(File.dirname(__FILE__) + '/description.xml', :port => 9292) do
  cross_site_xhr true

  on resource do
    run Bar if get '*'
    run Echo if websocket
  end
end.loop!
