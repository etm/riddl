require 'rack'
require '../../lib/ruby/server'
require 'pp'

use Rack::ShowStatus

class Test < Riddl::Implementation
  def response  
    Riddl::Parameter::Complex.new("ret","text/html","<strong>hello</strong> world")
  end  
end

run Riddl::Server.new("description4.xml") {
  on resource do
    run Test if get 'test'
  end  
}
