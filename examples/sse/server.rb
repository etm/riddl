#!/usr/bin/ruby
require 'pp'
require File.expand_path(File.dirname(__FILE__) + '/../../lib/ruby/riddl/server')

class Bar < Riddl::Implementation
  def response
    $connections_mutex.synchronize do
      $connections.each do |c|
        c.send('some data')
      end
    end
    Riddl::Parameter::Complex.new("return","text/plain","hello world")
  end
end

$connections = []
$connections_mutex = Mutex.new

class Echo < Riddl::SSEImplementation
  def onopen
    # if true (or any object for that matter) is returned, then 200 is sent
    # if false (or nil) is returned 404, the sse is denied
    puts "Connection established"
    $connections_mutex.synchronize { $connections << self }
  end

  def onclose
    puts "Connection closed"
    $connections_mutex.synchronize { $connections.delete(self) }
  end
end

Riddl::Server.new(File.dirname(__FILE__) + '/description.xml', :port => 9292) do
  cross_site_xhr true

  parallel do
    loop do
      $connections_mutex.synchronize do
        $connections.each do |c|
          c.send('heartbeat')
        end
      end
      sleep 15
    end
  end

  on resource do
    run Bar if get
    run Bar if get 'rrrr'
    run Bar if get 'xxxxx'
    run Echo if sse
  end
end.loop!
