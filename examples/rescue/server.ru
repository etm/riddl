#!/usr/bin/ruby

require 'rack'
require 'socket'
require '../../lib/ruby/server'
require 'lib/MarkUS_V3.0'
require 'xml/smart'
require 'fileutils'

#require 'logger'


require 'lib/rescue'

use Rack::ShowStatus

options = {:Port => 9290, :Host => "0.0.0.0", :AccessLog => []}
$0 = "RESCUE"


run(
  Riddl::Server.new("description.xml") do
  $0 = "RESCUE - Server Port: 9290"
    process_out false
    cross_site_xhr true
    on resource do
        p 'Processing description ....' if method :riddl => '*'
        run GetDescription if method :riddl => '*'

      on resource 'groups' do
        # Generating the ATOM feed with groups
        run GenerateFeed if method :get => '*'
        run AddResource if method :post => 'group'

        on resource do # Group-level
          run GenerateFeed if method :get => '*'
          run GetInterface if method :get => 'properties'
          run GetServiceInterface if method :get => 'serviceSchema'
          run UpdateResource if method :put => 'rename'
          run DeleteResource if method :delete => '*'
          run AddResource if method :post => 'subgroup'

          on resource 'operations' do
            on resource do
              run GetInterface if method :get => 'input'
              run GetInterface if method :get => 'output'
            end
          end
          on resource do # Subgroup-level
            run GenerateFeed if method :get => '*'
            run DeleteResource if method :delete => '*'
            run UpdateResource if method :put => 'rename'
            run AddResource if method :post => 'service'
  
            on resource do # Service-level
              run GetServiceDescription if method :get => '*'
              run UpdateResource if method :put => 'rename'
              run UpdateResource if method :put => 'service-properties'
              run DeleteResource if method :delete => '*'
              on resource do # operations of service
                run GetOperationWorkflow if method :get => '*'
              end
            end      
          end      
        end      

      end
    end
  end
)
