require 'rack'
require 'socket'
require '../../lib/ruby/riddl'
require 'pp'

use Rack::ShowStatus

class BookQuery < Riddl::Implementation
  def content  
    "hello world"
  end  
end

run(
  Riddl::Server.new("description.xml") do
    on resource do
      on resource "books" do
        run BookQuery if get 'book-query'
      end
    end
  end
)
