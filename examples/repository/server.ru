require 'rack'
require 'socket'
require '../../lib/ruby/server'
require 'libs/MarkUS_V3.0'
require 'xml/smart'

require 'libs/impl_groups'
require 'libs/impl_subgroups'

use Rack::ShowStatus

run(
  Riddl::Server.new("description.xml") do
    process_out false
    on resource do
      on resource 'groups' do
        p 'Processing groups ....'
        run Groups if get '*'
         on resource do
           p "Processing subgroups of ..." 
           # run Subgroups if get '*'
         end
      end
    end
  end
)
