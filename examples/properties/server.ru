require 'rack'
require 'socket'
require '../../lib/ruby/server'
require '../../lib/ruby/utils/properties'
require 'pp'

use Rack::ShowStatus

run Riddl::Server.new("description.xml") {
  process_out false
  on resource do
    run Riddl::Utils::Properties, "properties.xml", "properties.schema"
  end
}
