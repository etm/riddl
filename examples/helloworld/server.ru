require 'rack'
require '../../lib/ruby/server'
require 'pp'

use Rack::ShowStatus

class Bar < Riddl::Implementation
  def response 
    Riddl::Parameter::Simple.new("hellotest","hello world")
  end  
end

run(
  Riddl::Server.new("description.xml") do
    on resource do
      run Bar if post 'hello'
      run Bar if post 'hello-form'
      run Bar if get '*'
      run Bar if get 'type-html'
      on resource do
        run Bar if get '*'
        run Bar if put 'hello'
        run Bar if delete '*'
      end
      on resource 'hello' do
        run Bar if get '*'
        run Bar if put 'hello'
        run Bar if delete '*'
      end
    end
  end
)
