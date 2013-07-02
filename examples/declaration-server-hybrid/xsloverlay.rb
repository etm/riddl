#!/usr/bin/ruby
require 'pp'
require File.expand_path(File.dirname(__FILE__) + '/../../lib/riddl/server')
require File.expand_path(File.dirname(__FILE__) + '/../../lib/riddl/utils/xsloverlay')

Riddl::Server.new(File.dirname(__FILE__) + '/xsloverlay.xml', :port => 9294) do
  # accessible_description true

  on resource do
    run Riddl::Utils::XSLOverlay, "/xsls/instances.xsl"  if get && declaration_resource == '/'
    run Riddl::Utils::XSLOverlay, "/xsls/info.xsl"       if get && declaration_resource == '/{}'
    run Riddl::Utils::XSLOverlay, "/xsls/properties.xsl" if get && declaration_resource == '/{}/properties'
    run Riddl::Utils::XSLOverlay, "/xsls/values.xsl"     if get && declaration_resource == '/{}/properties/values'
  end
end.loop!
