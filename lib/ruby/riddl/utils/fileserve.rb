require 'mime/types'
require 'charlock_holmes'
require 'digest/md5'

module Riddl
  module Utils
    class FileServe < Riddl::Implementation
      def response
        path = File.file?(@a[0]) ? @a[0] : "#{@a[0]}/#{@r[@match.length-1..-1].join('/')}".gsub(/\/+/,'/')

        if File.directory?(path)
          @status = 404
          return []
        end
        if File.exists?(path)
          mtime = File.mtime(path)
          @headers << Riddl::Header.new("Last-Modified",mtime.httpdate)
          @headers << Riddl::Header.new("ETag",Digest::MD5.hexdigest(mtime.httpdate))
          htime = @env["HTTP_IF_MODIFIED_SINCE"].nil? ? Time.at(0) : Time.parse(@env["HTTP_IF_MODIFIED_SINCE"])
          if htime == mtime
            @headers << Riddl::Header.new("Connection","close")
            @status = 304 # Not modified
            return []
          else 
            mt = MIME::Types.type_for(path).first
            apx = ''
            if mt.ascii?
              tstr = File.read(path,CharlockHolmes::EncodingDetector::DEFAULT_BINARY_SCAN_LEN)
              apx = ';charset=' + CharlockHolmes::EncodingDetector.detect(tstr)[:encoding]
            end
            return Riddl::Parameter::Complex.new('file',mt.to_s + apx,File.open(path,'r'))
          end  
        end
        @status = 404
      end  
    end
  end  
end  
