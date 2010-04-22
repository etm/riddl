#\ -p 9292
require 'pp'
require 'fileutils'
require '../../lib/ruby/server'

use Rack::ShowStatus

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

run Riddl::Server.new(::File.dirname(__FILE__) + '/description.xml') {
  on resource do
    run Bar if get '*'
    run Echo if websocket
  end
}