require 'rack'
require '../../../lib/ruby/server'
require '../Helpers/gps.rb'
require 'pp'

EXIF = '/usr/bin/exiftool'

class Exif < Riddl::Implementation
  def response
    photo = author = title = description = tags = longitude = latitude = nil
    photo       = @p.detect { |e| e.name == 'photo' }
    author      = @p.detect { |e| e.name == 'author' }
    title       = @p.detect { |e| e.name == 'title' }
    description = @p.detect { |e| e.name == 'description' }
    tags        = @p.detect { |e| e.name == 'tags' }
    longitude   = @p.detect { |e| e.name == 'longitude' }
    latitude    = @p.detect { |e| e.name == 'latitude' }
    pname = photo.value.path
    `#{EXIF} -exif:Artist=\"#{author.value}\"         #{pname}`
    `#{EXIF} -exif:XPAuthor=\"#{author.value}\"       #{pname}`
    `#{EXIF} -exif:XPTitle=\"#{title.value}\"         #{pname}`
    `#{EXIF} -exif:XPSubject=\"#{title.value}\"       #{pname}`
    `#{EXIF} -exif:XPComment=\"#{description.value}\" #{pname}`
    `#{EXIF} -exif:XPKeywords=\"#{tags.value}\"       #{pname}`

    lat = latitude.value.to_f
    lng = longitude.value.to_f
    `#{EXIF} -exif:GPSLatitudeRef=\"#{GPS::pos_or_neg(lat,'N','S')}\" #{pname}`
    `#{EXIF} -exif:GPSLatitude=\"#{lat}\"                             #{pname}`
    `#{EXIF} -exif:GPSLongitudeRef="#{GPS::pos_or_neg(lng,'E','W')}\" #{pname}`
    `#{EXIF} -exif:GPSLongitude=\"#{lng}\"                            #{pname}`
    
    photo.reopen

    @p.delete_if do |e| 
      e.name == 'author' || e.name == 'longitude' || e.name == 'latitude'
    end
    @p
  end  
end

run Riddl::Server.new("exif.xml") {
  process_out true
  on resource do
    run Exif if post 'jpegdata'
  end
}
