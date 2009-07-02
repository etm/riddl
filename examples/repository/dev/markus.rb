#!/usr/bin/ruby
require 'libs/MarkUS_V3.0'

class Groups
  include MarkUSModule

  def response
    feed_ :xmlns => 'http://www.w3.org/2005/atom', :'prefix_!' => 'des' do
      title_ 'List of groups'
    end  
  end  
end  

t = Groups.new
p t.response
