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
            <title>#{title}</title>
            <author>Agador</author>
            #{authors.join}
          </book>  
        </books>
      END
    end
  end
end

$workflowengines = array();

run(
  Riddl::Server.new("description.xml") do
    on resource do
      
      on resource do
        on resource "properties" do
          run BookQuery if method :get => '*'
          run BookQuery if method :get => 'pairs'
          run BookQuery if method :start => 
        end
      end
    end
  end
)
