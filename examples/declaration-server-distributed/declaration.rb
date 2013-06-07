#!/usr/bin/ruby
require File.expand_path(File.dirname(__FILE__) + '/../../lib/riddl/server')

Riddl::Server.new(File.dirname(__FILE__) + '/declaration.xml', :port => 9297).loop!
