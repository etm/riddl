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

run Riddl::Server.new(::File.dirname(__FILE__) + '/description.xml') {
  on resource do
    run Bar if get '*'
  end
}
