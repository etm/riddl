#!/usr/bin/ruby
$0    = "downloadify"

require 'pp'
require 'fileutils'
require 'rubygems'
require '../../lib/ruby/server'
require '../../lib/ruby/utils/downloadify'

Riddl::Server::config!(File.expand_path(File.dirname(__FILE__)))
Riddl::Server.new(::File.dirname(__FILE__) + '/server.declaration.xml') do
  accessible_description true

  on resource do
    on resource do
      run Riddl::Utils::Downloadify if get 'dfin'
      run Riddl::Utils::Downloadify if post 'dfin'
    end
  end
end.loop!
