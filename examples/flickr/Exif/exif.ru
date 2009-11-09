require 'rack'
require '../../lib/ruby/server'
require 'pp'

class Exif < Riddl::Implementation
  def response
    photo       = @p.detect { |e| e.name == 'photo' }
    author      = @p.detect { |e| e.name == 'author' }
    title       = @p.detect { |e| e.name == 'title' }
    description = @p.detect { |e| e.name == 'description' }
    tags        = @p.detect { |e| e.name == 'tags' }
    longitude   = @p.detect { |e| e.name == 'longitude' }
    latitude    = @p.detect { |e| e.name == 'latitude' }
    pp photo
    @p.delete_if do |e| 
      e.name == 'author' || e.name == 'longitude' || e.name == 'latitude'
    end
    @p
  end  
end

run Riddl::Server.new("main.xml") {
  process_out true
  on resource do
    run Exif if post 'jpegdata'
  end
}
