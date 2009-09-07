#!/usr/bin/ruby
require 'rack'
require 'socket'
require '../../../lib/ruby/server'
require '../libs/MarkUS_V3.0'
require 'xml/smart'
require 'fileutils'

require 'main'
require 'about'
require 'root'
#require 'libs/impl_services'
#require 'libs/impl_details'
#require 'libs/impl_root'

use Rack::ShowStatus

run(
  Riddl::Server.new("description.xml") do
    process_out false
    
    on resource do
      # Show the entrie-screen and get re-ridected
      on resource '123' do

        # Browse repository (Groups)
        on resource 'rescue' do

          # Browse repository (Subgroups)
          on resource do 

            # Browse repository (Services)
            on resource do 
            end
          end
        end

        on resource 'wallet' do
        end

        on resource 'workflows' do
        end

        on resource 'preferences' do
        end

        on resource 'about' do
          p "Calling About" if method :get => '*'
          run About if method :get => '*'
        end
      end
    end
    on resource 'js' do
      on resource do
        p "Requesting Java-Script"  if method :get => '*'
        run GetJS if method :get => '*'
      end
    end
    on resource 'themes' do
      on resource 'img' do
        on resource
          p "Requesting Image" if method :get => '*'
          run GetImage if method :get => '*'
        end
      end
      on resource do
        p "Requesting Themes" if method :get => '*'
        run GetTheme if method :get => '*'
      end
    end
  end
)
