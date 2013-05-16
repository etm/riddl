#!/usr/bin/ruby
require 'pp'
require File.expand_path(File.dirname(__FILE__) + '/../../lib/riddl/server')
require File.expand_path(File.dirname(__FILE__) + '/../../lib/riddl/utils/declaration')

Riddl::Server.new(File.dirname(__FILE__) + '/declaration.xml', :port => 9297).loop!
