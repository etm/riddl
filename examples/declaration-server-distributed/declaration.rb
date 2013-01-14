#!/usr/bin/ruby
require 'pp'
require File.expand_path(File.dirname(__FILE__) + '/../../lib/riddl/server')
require File.expand_path(File.dirname(__FILE__) + '/../../lib/riddl/utils/declaration')

Riddl::Server.new(File.dirname(__FILE__) + '/declaration.xml', :port) do
  on resource do
    run Riddl::Utils::Declaration::Orchestrate, facade unless get 'riddl-description-request'
  end
end
