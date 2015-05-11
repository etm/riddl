require 'mime/types'
require 'charlock_holmes'
require 'digest/md5'
require 'xml/smart'

module Riddl
  module Utils
    class XMLServe < Riddl::Implementation
      def response
        path = File.file?(@a[0]) ? @a[0] : nil
        xpath = @a[1]

        if path.nil? || File.directory?(path)
          @status = 404
          return []
        end
        if File.exists?(path)
          mtime = File.mtime(path)
          @headers << Riddl::Header.new("Last-Modified",mtime.httpdate)
          @headers << Riddl::Header.new("Cache-Control","max-age=15552000, public")
          @headers << Riddl::Header.new("ETag",Digest::MD5.hexdigest(mtime.httpdate))
          htime = @env["HTTP_IF_MODIFIED_SINCE"].nil? ? Time.at(0) : Time.parse(@env["HTTP_IF_MODIFIED_SINCE"])
          if htime == mtime
            @headers << Riddl::Header.new("Connection","close")
            @status = 304 # Not modified
            return []
          else 
            if xpath 
              res = XML::Smart.open(path).find(xpath)
              return Riddl::Parameter::Complex.new('file','text/xml',res.any? ? res.first.dump : '<empty/>')
            else
              return Riddl::Parameter::Complex.new('file','text/xml',File.open(path,'r'))
            end
          end  
        end
        @status = 404
      end  
    end
  end  
end  
