#\ -p 9295
require 'pp'
require '../../lib/ruby/server'
require '../../lib/ruby/utils/properties'

use Rack::ShowStatus
$0 = "dsd-properties"

run Riddl::Server.new(File.dirname(__FILE__) + '/properties-1_0.xml') {
  schema, strans = Riddl::Utils::Properties::schema(File.dirname(__FILE__) + '/instances/properties.schema')

  on resource do |r|
    ### header RIDDL_DECLARATION_PATH holds the full path used in the declaration
    ### from there we get the instance, which is not present in the path used for properties
    instance = if r[:h]['RIDDL_DECLARATION_PATH']
      File.dirname(__FILE__) + '/instances/' + r[:h]['RIDDL_DECLARATION_PATH'].split('/')[1] + '/'
    else 
      File.dirname(__FILE__) + '/instance_test/'
    end  
    properties     = Riddl::Utils::Properties::file(instance + 'properties.xml')

    use Riddl::Utils::Properties::implementation(properties, schema, strans)
  end
}
