require 'rack'
require 'socket'
require '../../lib/ruby/server'
require '../../lib/ruby/utils/properties'
require 'pp'

use Rack::ShowStatus

run Riddl::Server.new("description.xml") {
  process_out false

  properties  = "properties.xml"
  fschema     = "properties.schema"
  if !File.exists?(properties) || !File.exists?(fschema)
    raise "properties or schema file not found"
  end
  schema      = XML::Smart::open(fschema)
  schema.namespaces = { 'p' => 'http://riddl.org/ns/common-patterns/properties/1.0' }
  if !File::exists?(Riddl::Utils::Properties::PROPERTIES_SCHEMA_XSL_RNG)
    raise "properties schema transformation file not found"
  end  
  strans = schema.transform_with(XML::Smart::open(Riddl::Utils::Properties::PROPERTIES_SCHEMA_XSL_RNG))

  on resource do
    run Riddl::Utils::Properties::All, properties, schema, strans if get
    run Riddl::Utils::Properties::Query, properties, schema, strans if get 'query'
    on resource 'schema' do
      run Riddl::Utils::Properties::Schema, properties, schema, strans if get
      on resource 'rng' do
        run Riddl::Utils::Properties::RngSchema, properties, schema, strans if get
      end  
    end
    on resource 'values' do
      run Riddl::Utils::Properties::Keys, properties, schema, strans if get
      run Riddl::Utils::Properties::AddPair, properties, schema, strans if post 'key-value-pair'
      on resource do |res|
        run Riddl::Utils::Properties::AddPair, properties, schema, strans if post 'key-value-pair'
        run Riddl::Utils::Properties::Values, properties, schema, strans if get
        run Riddl::Utils::Properties::Delete, properties, schema, strans if delete
        run Riddl::Utils::Properties::Put, properties, schema, strans if put 'value'
      end
    end  
  end
}
