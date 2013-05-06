#!/usr/bin/ruby
require 'pp'
require File.expand_path(File.dirname(__FILE__) + '/../../lib/riddl/server')
require File.expand_path(File.dirname(__FILE__) + '/../../lib/riddl/utils/properties')

Riddl::Server.new($basepath + '/description.xml') do
  schema, strans = Riddl::Utils::Properties::schema(File.dirname(__FILE__) + '/server.properties.schema')
  properties = Riddl::Utils::Properties::file(File.dirname(__FILE__) + '/server.properties.xml')

  interface 'main' do
    use Riddl::Utils::Properties::implementation(properties, schema, strans)
  end

  interface 'xsls' do
    run Riddl::Utils::FileServe, "xsls" if get
  end

  interface 'xsloverlay' do
    run Riddl::Utils::XSLOverlay, "xsls", "/xsls" if get
  end
end.loop!
