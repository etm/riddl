#!/usr/bin/ruby
require 'pp'
require File.expand_path(File.dirname(__FILE__) + '/../../lib/riddl/server')
require File.expand_path(File.dirname(__FILE__) + '/../../lib/riddl/utils/properties')

Riddl::Server.new('properties.xml') do
  schema, strans = Riddl::Utils::Properties::schema(@riddl_opts[:basepath] + '/server.properties.schema')
  properties = Riddl::Utils::Properties::file(@riddl_opts[:basepath] + '/server.properties.xml')

  on resource do
    use Riddl::Utils::Properties::implementation(properties, schema, strans)
  end
end.loop!
