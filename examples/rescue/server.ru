#\ -p 9290
$0 = "RESCUE"

require 'rack'
require 'socket'
require '../../lib/ruby/server'
require '../../lib/ruby/utils/fileserve'
require '../../lib/ruby/utils/erbserve'
require 'lib/MarkUS_V3.0'
require 'xml/smart'
require 'fileutils'
require 'pp'
require 'active_support'

require 'lib/Rescue'
require 'lib/Selection'
require 'lib/InjectionService'
require 'lib/InjectionHandler'

use Rack::ShowStatus

run(
  Riddl::Server.new("description.xml") do
  $0 = "RESCUE - Server Port: 9290"
    process_out false
    cross_site_xhr true
    on resource do
      run Riddl::Utils::FileServe, 'description.xml' if method :get => 'riddl-description'
      on resource 'xsl' do
        run Riddl::Utils::ERBServe, 'rng+xsl' if method :get => '*'
      end
      on resource 'injection' do
        on resource 'handler' do
          run InjectionHandler if method :post => 'injection-handler-request'
          run InjectionHandler if method :get => 'injection-instance-queue-request'
          run InjectionHandler if method :get => '*'
          run InjectionHandler if method :post => '*'
          run InjectionHandler if method :put => 'change-position'
        end
        on resource 'service' do
          run InjectionService if method :post => 'injection-service-request' 
        end
      end
      on resource 'select' do
        on resource 'random' do
          run SelectByRandom if method :post => '*'
        end
        on resource 'pgwl' do
          run GetSelectionData if method :get => '*'
          run PostSelectByUser if method :post => '*'
        end
      end
      on resource 'groups' do
        # Generating the ATOM feed with groups
        run GenerateFeed if method :get => '*'
        run AddResource if method :post => 'group'

        on resource do # Group-level
          run GenerateFeed if method :get => '*'
          run GetInterface if method :get => 'properties'
          run GetServiceInterface if method :get => 'service-schema'
          run UpdateResource if method :put => 'rename'
          run DeleteResource if method :delete => '*'
          run AddResource if method :post => 'subgroup'

          on resource 'operations' do
            run GetOperations if method :get => "*"
            on resource do
              run GetInterface if method :get => '*'
              run GetInterface if method :get => 'input'
              run GetInterface if method :get => 'output'
              on resource 'templates' do
                on resource do
                  run GetTemplates if method :get => '*'
                end
              end
            end
          end
          on resource do # Subgroup-level
            run GenerateFeed if method :get => '*'
            run DeleteResource if method :delete => '*'
            run UpdateResource if method :put => 'rename'
            run AddResource if method :post => 'service'
            on resource 'operations' do
              run GetOperations if method :get => "*"
              on resource do
                run GetInterface if method :get => '*'
                run GetInterface if method :get => 'input'
                run GetInterface if method :get => 'output'
              end
            end
  
            on resource do # Service-level
              run GetServiceDescription if method :get => '*'
              run UpdateResource if method :put => 'rename'
              run UpdateResource if method :put => 'service-description'
              run DeleteResource if method :delete => '*'
              on resource 'operations' do
                run GetOperations if method :get => "*"
                on resource do
                  run GetInterface if method :get => '*'
                  run GetInterface if method :get => 'input'
                  run GetInterface if method :get => 'output'
                  on resource 'templates' do
                    on resource do
                      run GetTemplates if method :get => '*'
                    end
                  end
                end
              end
            end      
          end      
        end      

      end
    end
  end
)
