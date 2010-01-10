#\ -p 9297
require 'pp'
require 'fileutils'
require '../../lib/ruby/server'
require '../../lib/ruby/utils/declaration'

use Rack::ShowStatus
$0 = "dsd-declaration"

run Riddl::Server.new(File.dirname(__FILE__) + '/declaration.xml') {
  process_out false
  on resource do
    run Riddl::Utils::Declaration::Description, description_string if get 'riddl-description-request'
    run Riddl::Utils::Declaration::Orchestrate, facade unless get 'riddl-description-request'
  end
}
