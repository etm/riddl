#!/usr/bin/ruby
require 'pp'
require File.expand_path(File.dirname(__FILE__) + '/../../lib/riddl/server')
require File.expand_path(File.dirname(__FILE__) + '/../../lib/riddl/utils/properties')
require File.expand_path(File.dirname(__FILE__) + '/../../lib/riddl/utils/xsloverlay')
require File.expand_path(File.dirname(__FILE__) + '/../../lib/riddl/utils/fileserve')

Riddl::Server.new('declaration.xml') do
  schema, strans = Riddl::Utils::Properties::schema(@riddl_opts[:basepath] + '/server.properties.schema')
  properties = Riddl::Utils::Properties::file(@riddl_opts[:basepath] + '/server.properties.xml')

  interface 'main' do
    use Riddl::Utils::Properties::implementation(properties, schema, strans)
  end

  interface 'xsls' do |r|
    run Riddl::Utils::FileServe, "xsls" if get
  end

  interface 'xsloverlay' do
    run Riddl::Utils::XSLOverlay, "/xsls/properties.xsl" if get && declaration_resource == '/'
    run Riddl::Utils::XSLOverlay, "/xsls/values.xsl"     if get && declaration_resource == '/values'
  end
end.loop!
