require 'mime/types'
require 'digest/md5'

module Riddl
  module Utils
    class Downloadify < Riddl::Implementation
      def response
        mimetype = @p.find{|e|e.name == 'mimetype'}.value
        content = @p.find{|e|e.name == 'content'}.value
        if filename = @p.find{|e|e.name == 'filename'}
          Riddl::Parameter::Complex.new("content",mimetype,content,filename.value)
        else  
          Riddl::Parameter::Complex.new("content",mimetype,content,'change_me.ext')
        end
      end  
    end
  end  
end  
