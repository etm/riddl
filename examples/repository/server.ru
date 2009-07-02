require 'rack'
require 'socket'
require '../../lib/ruby/server'
require 'libs/MarkUS_V3.0'
require 'xml/smart'
require 'libs/impl_groups'

use Rack::ShowStatus

run(
  Riddl::Server.new("description.xml") do
    process_out false
    on resource do                                    # "/"
      on resource 'groups' do
        run Groups if get '*'
      end
    end
  end
)
