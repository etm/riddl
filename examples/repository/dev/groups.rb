#!/usr/bin/ruby

require 'libs/MarkUS_V3.0'
require 'time'
require 'rubygems'
gem 'ruby-xml-smart', '>= 0.2.0.1'
require 'xml/smart'

$url = 'http://localhost:9292/'

class Groups
  include MarkUSModule

  def response
    @__markus_indent = true
    groups = []
    Dir['repository/groups/*'].each do |f|
      if File::directory? f
        groups << File::basename(f) 
      end  
    end  

    feed = feed_ :xmlns => 'http://www.w3.org/2005/atom' do
      title_ 'List of groups'
      updated_ 'No date at the monent'
      generator_ 'My Repository at local host'
      id_ "#{$url}groups/"
      link_ :rel => 'self', :type => 'application/atom+xml', :href => "#{$url}groups/"
      groups.each do |g|
        entry_ do
          id_ "#{$url}groups/#{g}/"
          link_ "#{$url}groups/#{g}/"
          updated_ File.mtime("repository/groups/#{g}").xmlschema
        end
      end  
    end  
    puts feed
  end  
end  

t = Groups.new
t.response
