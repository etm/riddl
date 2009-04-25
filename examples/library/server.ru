require 'rack'
require 'socket'
require '../../lib/ruby/server'
require 'pp'

use Rack::ShowStatus

class BookQuery < Riddl::Implementation
  def response  
    [
      Riddl::ParameterIO.new("list-of-books","text/xml") do |struct|
        <<-END
          <books>
            <book id="1">
              <author>Agador</author>
              <title>Mu</title>
            </book>  
          </books>"
        END
      end
    ]
  end
  def headers
    []
  end
  def status
    200
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
