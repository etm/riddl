#!/usr/bin/ruby
require File.expand_path(File.dirname(__FILE__) + '/../../lib/riddl/server')

class Test < Riddl::Implementation
  def response  
    Riddl::Parameter::Complex.new("ret","text/html","<strong>hello</strong> world")
  end  
end

Riddl::Server.new("description4.xml") do
  on resource do
    run Test if get 'test'
  end  
end.loop!
