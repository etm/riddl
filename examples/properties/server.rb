#!/usr/bin/ruby
require 'pp'
require File.expand_path(File.dirname(__FILE__) + '/../../lib/riddl/server')
require File.expand_path(File.dirname(__FILE__) + '/../../lib/riddl/utils/properties')

Riddl::Server.new($basepath + '/description.xml') do
  schema, strans = Riddl::Utils::Properties::schema(File.dirname(__FILE__) + '/properties.schema')
  properties = Riddl::Utils::Properties::file(File.dirname(__FILE__) + '/properties.xml')

  on resource do
    use Riddl::Utils::Properties::implementation(properties, schema, strans)
  end
end.loop!
