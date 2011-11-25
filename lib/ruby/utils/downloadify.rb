require 'mime/types'
require 'digest/md5'

module Riddl
  module Utils
    class Downloadify < Riddl::Implementation
      def response
        mimetype = @p.find{|e|e.name == 'mimetype'}.value
        content = @p.find{|e|e.name == 'content'}.value
        Riddl::Parameter::Complex.new("content",mimetype,content,@r.last)
      end  
    end
  end  
end  
