require 'rubygems'
gem 'minitest', '=4.7.4'
require 'minitest/autorun'
require 'socket'

class TestServerInfo
  attr_reader :server,:schema
  attr_accessor :url, :port

  def initialize(server,schema)
    @server = server
    @schema = schema
  end
end

module ServerCase 
  def setup
    self.class::SERVER.each do |s|
      if self.class::NORUN
        out = `#{s.server} info`
        s.port = out.match(/:(\d+)\)/)[1].to_i
        s.url = out.match(/\(([^\)]+)\)/)[1]
      else  
        out = `#{s.server} start`
        s.port = out.match(/:(\d+)\)/)[1].to_i
        s.url = out.match(/\(([^\)]+)\)/)[1]

        up = false
        until up
          begin
            TCPSocket.new('localhost', s.port)
            up = true
          rescue => e
            sleep 0.2
          end  
        end
      end
    end
  end

  def teardown
    unless self.class::NORUN
       self.class::SERVER.each do |s|
        `#{s.server} stop`
       end 
    end 
  end
end
