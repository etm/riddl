#!/usr/bin/ruby
require File.expand_path(File.dirname(__FILE__) + '/../../lib/riddl/server')
require File.expand_path(File.dirname(__FILE__) + '/../../lib/riddl/utils/xsloverlay')
require File.expand_path(File.dirname(__FILE__) + '/../../lib/riddl/utils/fileserve')
Riddl::Server.new(File.dirname(__FILE__) + '/declaration.xml', :port => 9297) do

  interface 'xsloverlay' do
    run Riddl::Utils::XSLOverlay, "/xsls/instances.xsl"  if get && declaration_resource == '/'
    run Riddl::Utils::XSLOverlay, "/xsls/info.xsl"       if get && declaration_resource == '/{}'
    run Riddl::Utils::XSLOverlay, "/xsls/properties.xsl" if get && declaration_resource == '/{}/properties'
  end

  interface 'xsls' do
    on resource do
      run Riddl::Utils::FileServe, "xsls" if get
    end  
  end

end.loop!
