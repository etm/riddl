#!/usr/bin/ruby
require File.expand_path(File.dirname(__FILE__) + '/../../lib/ruby/riddl/server')
require File.expand_path(File.dirname(__FILE__) + '/../../lib/ruby/riddl/commonlogger')
require File.expand_path(File.dirname(__FILE__) + '/../../lib/ruby/riddl/utils/erbserve')

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

Riddl::Server.new("main.xml", :port => 9001) do
  process_out false
  logger Riddl::CommonLogger.new("Main","main.log")
  on resource do
    run A if get 'a'
    run B if get 'b'
    run C if get 'c'
    run S if get '*'
  end
end.loop!
