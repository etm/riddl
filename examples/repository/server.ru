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
        p 'Creating group ...' if method(:POST => 'create-group-form') || method(method :POST => 'create-group')
        run GroupsPOST if method(:POST => 'create-group-form') || method(method :POST => 'create-group')
        on resource do
          p 'Processing subgroups ...' if get '*' 
          run SubgroupsGET if get '*'
          p 'Creating subgroup ...' if method(:POST => 'create-subgroup-form') || method(method :POST => 'create-subgroup') 
          run SubgroupsPOST if method(:post => 'create-subgroup-form') || method(:POST => 'create-subgroup')
          on resource do
            p 'Processing services .... ' if get '*'
            run ServicesGET if get '*'
            p 'Creating service ...' if method :POST => 'create-service-form'
            run ServicesPOST if method :post => 'create-service-form'
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
