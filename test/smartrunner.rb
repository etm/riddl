require 'rubygems'
gem 'minitest', '=4.7.4'
require 'minitest/autorun'
require 'socket'

module ServerCase 
  def setup
    if self.class::NORUN
      out = `#{self.class::SERVER} info`
      @port = out.match(/:(\d+)\)/)[1].to_i
      @url = out.match(/\(([^\)]+)\)/)[1]
    else  
      out = `#{self.class::SERVER} start`
      @port = out.match(/:(\d+)\)/)[1].to_i
      @url = out.match(/\(([^\)]+)\)/)[1]

      up = false
      until up
        begin
          TCPSocket.new('localhost', @port)
          up = true
        rescue => e
          sleep 0.2
        end  
      end
    end  
  end

  def teardown
    unless self.class::NORUN
      `#{self.class::SERVER} stop`
    end 
  end
end
