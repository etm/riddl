#!/usr/bin/ruby
require File.expand_path(File.dirname(__FILE__) + '/../../lib/riddl/server')
require File.expand_path(File.dirname(__FILE__) + '/../../lib/utils/downloadify')

Riddl::Server.new(::File.dirname(__FILE__) + '/server.declaration.xml', :port => 9299) do
  accessible_description true

  interface "main" do
  end

  interface "downloadify" do 
    on resource do
      run Riddl::Utils::Downloadify if get 'dfin'
      run Riddl::Utils::Downloadify if post 'dfin'
    end
  end
end.loop!
