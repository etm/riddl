#!/usr/bin/ruby
require 'pp'
require File.expand_path(File.dirname(__FILE__) + '/../../lib/ruby/riddl/server')
require File.expand_path(File.dirname(__FILE__) + '/../../lib/ruby/riddl/utils/properties')
require File.expand_path(File.dirname(__FILE__) + '/../../lib/ruby/riddl/utils/xsloverlay')
require File.expand_path(File.dirname(__FILE__) + '/../../lib/ruby/riddl/utils/fileserve')

Riddl::Server.new(File.dirname(__FILE__) + '/declaration.xml', :port => 9292) do
  accessible_description true

  backend = Riddl::Utils::Properties::Backend.new( 
    @riddl_opts[:basepath] + '/server.properties.schema', 
    @riddl_opts[:basepath] + '/server.properties.xml' 
  )

  interface 'main' do
    use Riddl::Utils::Properties::implementation(backend)
  end

  interface 'xsls' do |r|
    on resource do
      run Riddl::Utils::FileServe, "xsls" if get
    end  
  end

  interface 'xsloverlay' do
    run Riddl::Utils::XSLOverlay, "/xsls/properties.xsl" if get && declaration_resource == '/'
    run Riddl::Utils::XSLOverlay, "/xsls/values.xsl"     if get && declaration_resource == '/values'
  end
end.loop!
