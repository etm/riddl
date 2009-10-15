#!/usr/bin/ruby

require 'rack'
require 'socket'
require '../../lib/ruby/server'
require 'libs/MarkUS_V3.0'
require 'xml/smart'
require 'fileutils'

#require 'logger'


require 'libs/impl_groups'
require 'libs/impl_subgroups'
require 'libs/impl_services'
require 'libs/impl_details'
require 'libs/impl_root'
require 'libs/count'

use Rack::ShowStatus

options = {:Port => 9290, :Host => "0.0.0.0", :AccessLog => []}
$0 = "RESCUE"


run(
  Riddl::Server.new("description.xml") do
  $0 = "RESCUE - Server Port: 9290"
    process_out false
    on resource do
        p 'Processing description ....' if method :riddl => '*'
        run RootGET if method :riddl => '*'

        p 'Processing white information ....' if method :get => 'whiteInformation-request'
        run WhiteInformationGET if method :get => 'whiteInformation-request'
      
      on resource 'groups' do
        # Generating the ATOM feed with groups
        p 'Processing groups ....' if method :get => '*'
        run GroupsGET if method :get => '*'

        # Creating a new group
        p 'Create group ...' if method :post => 'create-group'
        run GroupPOST if method :post => 'create-group'

        on resource 'count' do
          # Generating the ATOM feed with the services
          p 'Count group entries .... ' if method :get => '*'
          run Count if method :get => '*'
        end
        
        on resource do # Group
          # Generating the ATOM feed with subgroups
          p 'Processing subgroups ...' if method :get => '*'
          run SubgroupsGET if method :get => '*'
        
          # Processing group-properties
          p 'Processing group-properties ...' if method :get => 'properties-of-group-request'
          run GroupProperties if method :get => 'properties-of-group-request'

          # Processing query-input
          p 'Processing query-input ...' if method :get => 'query-input-of-group-request'
          run GroupQueryInput if method :get => 'query-input-of-group-request'

          # Processing query-output
          p 'Processing query-output ...' if method :get => 'query-output-of-group-request'
          run GroupQueryOutput if method :get => 'query-output-of-group-request'

          # Processing invoke-intput
          p 'Processing invoke-intput ...' if method :get => 'invoke-input-of-group-request'
          run GroupInvokeInput if method :get => 'invoke-input-of-group-request'

          # Processing invoke-output
          p 'Processing invoke-output ...' if method :get => 'invoke-output-of-group-request'
          run GroupInvokeOutput if method :get => 'invoke-output-of-group-request'

          # Creating a new subgroup 
          p 'Creating subgroup ...' if method :post => 'create-subgroup' 
          run SubgroupPOST if method :post => 'create-subgroup'
          
          # Deleting a group from the repository 
          p 'Deleting groups ...' if method :delete => '*'
          run GroupDELETE if method :delete => '*'
          
          # Updating an existing group
          p 'Updating group ...' if method :put => 'create-group'
          run GroupPUT if method :put => 'create-group'

          on resource 'count' do
            # Generating the ATOM feed with the services
            p 'Count subgroup entries .... ' if method :get => '*'
            run Count if method :get => '*'
          end
          
          on resource do  # Subgrouop
            # Generating the ATOM feed with the services
            p 'Processing services .... ' if method :get => '*'
            run ServicesGET if method :get => '*'
            
            # Creating a new service
            p 'Creating service ...' if method :post => 'create-service'
            run ServicesPOST if method :post => 'create-service'

            # Updating an existing subgroup
            p 'Updating subgroup ...' if method :put => 'create-subgroup' 
            run SubgroupPUT if method :put => 'create-subgroup'

            
            # Deleting an existing subgroup
            p 'Deleting subgroup ...' if method :delete => '*'
            run SubgroupDELETE if method :delete => '*'

            on resource 'count' do
              # Generating the ATOM feed with the services
              p 'Count service entries .... ' if method :get => '*'
              run Count if method :get => '*'
            end
            
            on resource do  # Service
              # Responding the service details
              p 'Processing service details ....' if method :get => '*'
              run DetailsGET if method :get => '*'
              
              # Updating an existing service
              p 'Updating service ...' if method :put => 'create-service'
              run ServicesPUT if method :put => 'create-service'

              # Delete an existing service
              p 'Deleting service ....' if method :delete => '*'
              run ServicesDELETE if method :delete => '*'
              
            end
          end
        end
      end
    end
  end
)
