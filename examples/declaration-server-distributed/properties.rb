#!/usr/bin/ruby
require 'pp'
require '../../lib/ruby/server'
require '../../lib/ruby/utils/properties'

Riddl::Server.new('properties.xml', :port => 9295) do
  on resource do |r|
    ### header RIDDL_DECLARATION_PATH holds the full path used in the declaration
    ### from there we get the instance, which is not present in the path used for properties
    properties = if r[:h]['RIDDL_DECLARATION_PATH']
      @riddl_opts[:basepath] + '/instances/' + r[:h]['RIDDL_DECLARATION_PATH'].split('/')[1] + '/properties.xml'
    else 
      @riddl_opts[:basepath] + '/instances/1/properties.xml'
    end  
    backend = Riddl::Utils::Properties::Backend.new( 
      @riddl_opts[:basepath] + '/instances/properties.schema', 
      properties
    )

    use Riddl::Utils::Properties::implementation(backend)
  end
end.loop!
