#!/usr/bin/ruby
require 'pp'
require File.expand_path(File.dirname(__FILE__) + '/../../lib/ruby/riddl/server')

class Bar < Riddl::Implementation
  def response
    Riddl::Parameter::Complex.new("return","text/plain","hello world")
  end
end

class Echo < Riddl::SSEImplementation
  def onopen
    # if true (or any object for that matter) is returned, then 200 is sent
    # if false (or nil) is returned 404, the sse is denied
    puts "Connection established"
    Thread.new do
      1.upto 10 do |i|
        send("oasch #{i}")
        sleep 1
      end
      close
    end
  end

  def onclose
    puts "Connection closed"
  end
end

Riddl::Server.new(File.dirname(__FILE__) + '/description.xml', :port => 9292) do
  cross_site_xhr true

  on resource do
    run Bar if get
    run Bar if get 'rrrr'
    run Bar if get 'xxxxx'
    run Echo if sse
  end
end.loop!
