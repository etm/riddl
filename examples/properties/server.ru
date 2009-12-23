require 'rack'
require 'socket'
require '../../lib/ruby/server'
require '../../lib/ruby/utils/properties.rb'
require 'pp'

require 'lib/query'
require 'lib/schema'
require 'lib/rngschema'
require 'lib/all'
require 'lib/keys'
require 'lib/values'
require 'lib/addpair'
require 'lib/delete'
require 'lib/put'

use Rack::ShowStatus

run Riddl::Server.new("description.xml") {
  process_out false
  properties = "properties.xml"
  schema     = "properties.schema"
  if !File.exists?(properties) || !File.exists?(schema)
    raise "properties or schema file not found"
  end

  on resource do
    run All, properties, schema if get
    run Query, properties, schema if get 'query'
    on resource 'schema' do
      run Schema, properties, schema if get
      on resource 'rng' do
        run RngSchema, properties, schema if get
      end  
    end
    on resource 'values' do
      run Keys, properties, schema if get
      run AddPair, properties, schema if post 'key-value-pair'
      on resource do |res|
        run AddPair, properties, schema if post 'key-value-pair'
        run Values, properties, schema if get
        run Delete, properties, schema if delete
        run Put, properties, schema if put 'value'
      end
    end  
  end
}
