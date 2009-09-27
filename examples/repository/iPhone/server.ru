#!/usr/bin/ruby
require 'rack'
require 'socket'
require '../../../lib/ruby/server'
require '../../../lib/ruby/client'
require '../../../lib/ruby/header'
require '../../../lib/ruby/utils/fileserve'
require '../libs/MarkUS_V3.0'
require 'xml/smart'
require 'fileutils'

require 'libs/rescue'
require 'libs/wallet'
require 'libs/forward'
require 'libs/query'
require 'libs/show'
require 'libs/preferences'



use Rack::ShowStatus
options = {:Port => 9291, :Host => "0.0.0.0", :AccessLog => []}
$0 = "RESCUE: iPhone"

run(
  Riddl::Server.new('description.xml') do
    process_out false
    
    # Show the entrie-screen and get re-ridected
    on resource do
      run Forward if get

      on resource do
        run Riddl::Utils::FileServe, 'html/main.html' if method :get => '*'
        # Browse repository (Groups)

        on resource 'rescue' do
          p 'Executing RESCUE-request (rescue.rb)' if method :get => '*'
          run RESCUE if method :get => '*'
        end

        on resource 'wallet' do
          p 'Executing GetWallet (wallet.rb)' if method :get => '*'
          run GetWallet if method :get => '*'

          p 'Executing AddToWallet (wallet.rb)' if method :post => 'editWallet'
          run AddToWallet if method :post => 'editWallet'

          p 'Executing DeleteFromWallet (wallet.rb)' if method :delete => 'editWallet'
          run DeleteFromWallet if method :delete => 'editWallet'
        end
        on resource 'workflows' do
          p 'Executing GetWorkflows (workflows.rb)' if method :get => '*'
        end


        on resource 'preferences' do
          p 'Executing GetPreferences (prefernces.rb)' if method :get => '*'
          run PreferencesForm if method :get => '*'
          on resource 'schema' do
            p 'Responding preferences.schema (prefernces.rb)' if method :get => '*'
            run Riddl::Utils::FileServe, 'rngs/preferences.rng' if method :get => '*'
          end

          on resource do
            p 'Responding an attribute of the preferences (prefernces.rb)' if method :get => '*'
            run PreferencesValue if method :get => '*'
          end
        end

        on resource 'query' do
          p 'Dispose query (query.rb)' if method :get => 'disposeQuery'
          run DisposeQuery if method :get => 'disposeQuery'

          p 'Execute query (query.rb)' if method :get => '*'
          run ExecuteQuery if method :get => '*'
        end
      end

      on resource 'about' do
        run Riddl::Utils::FileServe, 'html/about.html' if method :get => '*'
      end
      on resource 'about2' do
        run Riddl::Utils::FileServe, 'html/about2.html' if method :get => '*'
      end
      on resource 'js' do
        run Riddl::Utils::FileServe, 'js' if method :get => '*'
      end

    end
  end
)
