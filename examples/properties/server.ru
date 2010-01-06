require '../../lib/ruby/server'
require '../../lib/ruby/utils/properties'
require 'pp'

use Rack::ShowStatus

run Riddl::Server.new("description.xml") {
  process_out false

  schema, strans = Riddl::Utils::Properties::schema(File.dirname(__FILE__) + '/properties.schema')
  properties = Riddl::Utils::Properties::file(File.dirname(__FILE__) + '/properties.xml')

  on resource do
    use Riddl::Utils::Properties::implementation(properties, schema, strans)
  end
}
