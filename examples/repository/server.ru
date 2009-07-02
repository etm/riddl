require 'rack'
require 'socket'
require '../../lib/ruby/server'
require 'libs/MarkUS_V3.0'
require 'xml/smart'

use Rack::ShowStatus

class Groups < Riddl::Implementation
  include MarkUSModule

  def response
    groups = []
    Dir['repository/groups/*'].each do |f|
      if File::directory? f
        groups << File::basename(f) 
      end  
    end  

    Riddl::Parameter::Complex.new("list-of-groups","text/xml") do
      feed__ :xmlns => 'http://www.w3.org/2005/atom' do
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
    end  
  end
end

run(
  Riddl::Server.new("description.xml") do
    process_out false
    on resource do                                    # "/"
      on resource 'groups' do
        run Groups if get '*'
      end
    end
  end
)
