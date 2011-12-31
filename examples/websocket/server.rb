#!/usr/bin/ruby
$0 = "websocket"

require 'rubygems'
require 'pp'
require 'fileutils'
require '../../lib/ruby/server'
require 'digest/md5'

class Bar < Riddl::Implementation
  def response  
    Riddl::Parameter::Complex.new("return","text/plain","hello world")
  end  
end

class Echo < Riddl::WebSocketImplementation
  def onopen
    puts "Connection established"
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

Riddl::Server.new($basepath + '/description.xml') do
  on resource do
    run Bar if get '*'
    run Echo if websocket
  end
end.loop!
