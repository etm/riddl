#!/usr/bin/ruby
require 'pp'
require File.expand_path(File.dirname(__FILE__) + '/../../lib/ruby/riddl/server')

class Test < Riddl::Implementation
  def response
    Riddl::Parameter::Complex.new("test","text/plain") do
      <<-END
        hello #{@r.length}
      END
    end
  end
end

class Sub < Riddl::Implementation
  def response
    Riddl::Parameter::Complex.new("sub","text/plain") do
      <<-END
        sub #{@r.length}
      END
    end
  end
end


Riddl::Server.new(File.dirname(__FILE__) + '/description.xml', :port => 9001, :bind => '::') do
  accessible_description true

  on resource do
    run Test if get
    on resource "hello" do
      run Test if get
      on resource "sub" do
        run Sub if get
      end
    end
  end
end.loop!
