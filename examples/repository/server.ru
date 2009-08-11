#!/usr/bin/ruby
require 'rack'
require 'socket'
require '../../lib/ruby/server'
require 'libs/MarkUS_V3.0'
require 'xml/smart'
require 'fileutils'

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
        # Generating the ATOM feed with groups
        p 'Processing groups ....' if method :get => '*'
        run GroupsGET if method :get => '*'

        # Creating a new group
        p 'Create group ...' if method :post => 'create-group'
        run GroupPOST if method :post => 'create-group'
        
        on resource do # Group
          # Generating the ATOM feed with subgroups
          p 'Processing subgroups ...' if method :get => '*'
          run SubgroupsGET if method :get => '*'
        
          # Creating a new subgroup 
          p 'Creating subgroup ...' if method :post => 'create-subgroup' 
          run SubgroupPOST if method :post => 'create-subgroup'
          
          # Deleting a group from the repository 
          p 'Deleting groups ...' if method :delete => '*'
          run GroupDELETE if method :delete => '*'
          
          # Updating the description of an existing group
          p 'Updating group decription ....' if method :put => 'update-group'
          run GroupPUT if method :put => 'update-group'
          
          on resource do  # Subgrouop
            # Generating the ATOM feed with the services
            p 'Processing services .... ' if method :get => '*'
            run ServicesGET if method :get => '*'
            
            # Creating a new service
            p 'Creating service ...' if method :post => 'create-service'
            run ServicesPOST if method :post => 'create-service'

            # Creating a new subgroup 
            p 'Updating subgroup ...' if method :put => 'create-subgroup' 
            run SubgroupPUT if method :put => 'create-subgroup'

            
            # Deleting an existing subgroup
            p 'Deleting subgroup ...' if method :delete => '*'
            run SubgroupDELETE if method :delete => '*'
            
            on resource do  # Service
              # Responding the service details
              p 'Processing service details ....' if method :get => '*'
              run DetailsGET if method :get => '*'
              
              # Delete an existing service
              p 'Deleting service ....' if method :delete => '*'
              run ServicesDELETE if method :delete => '*'
              
              # Updating an existing service
              # .....
              # .....

            end
          end
        end
      end
    end
  end
)
