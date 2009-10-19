require 'rack'
require 'socket'
require '../../lib/ruby/server'
require '../../lib/ruby/commonlogger'
require '../../lib/ruby/utils/erbserve'

require 'pp'

class A < Riddl::Implementation
  def response
    Riddl::Parameter::Simple.new("x","1")
  end
end  
class B < Riddl::Implementation
  def response
    Riddl::Parameter::Simple.new("y","1")
  end
end  
class C < Riddl::Implementation
  def response
    Riddl::Parameter::Simple.new("z","1")
  end
end  
class S < Riddl::Implementation
  def response
    @p # return input parameters unchanged
  end
end  

options[:Port] = 9201

run Riddl::Server.new("main.xml") {
    process_out false
    logger Riddl::CommonLogger.new("Main","main.log")
    on resource do
      run A if get 'a'
      run B if get 'b'
      run C if get 'c'
      run S if get '*'
    end
  end
}
