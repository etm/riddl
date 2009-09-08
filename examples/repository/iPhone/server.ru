#!/usr/bin/ruby
require 'rack'
require 'socket'
require '../../../lib/ruby/server'
require '../libs/MarkUS_V3.0'
require 'xml/smart'
require 'fileutils'
require 'logger'

require 'libs/main'
require 'libs/about'
require 'libs/root'
#require 'libs/impl_services'
#require 'libs/impl_details'
#require 'libs/impl_root'

use Rack::ShowStatus
options = {:Port => 9291, :Host => "0.0.0.0", :AccessLog => [Logger.new('server.log')]}
$0 = "RESCUE: iPhone"

run(
  Riddl::Server.new('description.xml') do
    process_out false
    
    # Show the entrie-screen and get re-ridected
    on resource do
      p 'Executing RootResource - that schould not happen' if method :get => '*'

      on resource '123' do

        # Browse repository (Groups)
        on resource 'rescue' do
          p 'Executing GetGroups (rescue.rb)' if method :get => '*'

          # Browse repository (Subgroups)
          on resource do 
            p 'Executing GetSubroups (rescue.rb)' if method :get => '*'

            # Browse repository (Services)
            on resource do 
              p 'Executing GetServices (rescue.rb)' if method :get => '*'
            end
          end
        end

        on resource 'wallet' do
          p 'Executing GetWallet (wallet.rb)' if method :get => '*'
        end

        on resource 'workflows' do
          p 'Executing GetWorkflows (workflows.rb)' if method :get => '*'
        end

        on resource 'preferences' do
          p 'Executing GetPreferences (prefernces.rb)' if method :get => '*'
        end
        on resource 'js' do
          on resource do
            p 'Executing GetJS (root.rb)'  if method :get => '*'
            run GetJS if method :get => '*'
          end
        end
        on resource 'themes' do
          on resource 'img' do
            on resource do
              p 'Executing GetImage (root.rb)' if method :get => '*'
              run GetImage if method :get => '*'
            end
          end
          on resource do
            p 'Executing GetTheme (root.rb)' if method :get => '*'
            run GetTheme if method :get => '*'
          end
        end
        on resource 'about' do
          p 'Executing About (about.rb)' if method :get => '*'
          run About if method :get => '*'
        end
      end
    end
  end
)
