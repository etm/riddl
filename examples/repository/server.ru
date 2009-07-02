require 'rack'
require 'socket'
require '../../lib/ruby/server'
require 'libs/MarkUS_V3.0'
require 'xml/smart'

require 'libs/impl_groups'
require 'libs/impl_subgroups'
require 'libs/impl_services'
require 'libs/impl_details'

use Rack::ShowStatus

run(
  Riddl::Server.new("description.xml") do
    process_out false
    on resource do
      on resource 'groups' do
        p 'Processing groups ....' if get '*'
        run GroupsGET if get '*'
         on resource do
           p 'Processing subgroups ...' if get '*' 
           run SubgroupsGET if get '*'
           on resource do
             p 'Processing services .... ' if get '*'
             run ServicesGET if get '*'
             on resource do
               p 'Processing service details ....' if get '*'
               run DetailsGET if get '*'
             end
           end
         end
      end
    end
  end
)
