#!/usr/bin/ruby
require 'rack'
require 'socket'
require '../../../lib/ruby/server'
require '../../../lib/ruby/client'
require '../../../lib/ruby/utils/fileserve'
require '../libs/MarkUS_V3.0'
require 'xml/smart'
require 'fileutils'
require 'logger'

require 'libs/rescue'

#require 'libs/root'
#require 'libs/impl_services'
#require 'libs/impl_details'
#require 'libs/impl_root'

use Rack::ShowStatus
options = {:Port => 9291, :Host => "0.0.0.0", :AccessLog => []}
$0 = "RESCUE: iPhone"

run(
  Riddl::Server.new('description.xml') do
    process_out false
    
    # Show the entrie-screen and get re-ridected
    on resource do
      p 'Executing RootResource - that schould not happen if forwarding is implenebted' if method :get => '*'

      on resource '123' do
        run Riddl::Utils::FileServe, 'html/main.html' if method :get => '*'
        # Browse repository (Groups)
        on resource 'rescue' do
          p 'Executing RESCUE-request (rescue.rb)' if method :get => '*'
          run RESCUE if method :get => '*'
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
