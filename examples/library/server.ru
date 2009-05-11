require 'rack'
require 'socket'
require '../../lib/ruby/server'
require 'pp'

use Rack::ShowStatus

class BookQuery < Riddl::Implementation
  def response
    authors = @p.map{|e|e.name == "author" ?  "<author>" + e.value + "</author>" : nil }.compact
    title = @p.map{|e|e.name == "title" ?  e.value : nil }.compact
    Riddl::Parameter::Complex.new("list-of-books","text/xml") do
      <<-END
        <books>
          <book id="1">
            <author>Agador</author>
            #{authors.join}
            <title>#{title}</title>
          </book>  
        </books>
      END
    end
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
        run BookQuery if method :get => 'book-query'
      end
    end
  end
)
