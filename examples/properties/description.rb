#!/usr/bin/ruby
require 'pp'
require File.expand_path(File.dirname(__FILE__) + '/../../lib/ruby/riddl/server')
require File.expand_path(File.dirname(__FILE__) + '/../../lib/ruby/riddl/utils/properties')

Riddl::Server.new(File.dirname(__FILE__) + '/properties.xml') do
  backend = Riddl::Utils::Properties::Backend.new( 
    @riddl_opts[:basepath] + '/server.properties.schema', 
    @riddl_opts[:basepath] + '/server.properties.xml'
  )

  on resource do
    use Riddl::Utils::Properties::implementation(backend)
  end
end.loop!
