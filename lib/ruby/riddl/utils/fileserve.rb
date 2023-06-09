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
        if File.exist?(path)
          mtime = File.mtime(path)
          @headers << Riddl::Header.new("Last-Modified",mtime.httpdate)
          @headers << Riddl::Header.new("ETag",Digest::MD5.hexdigest(mtime.httpdate))
          htime = @env["HTTP_IF_MODIFIED_SINCE"].nil? ? Time.at(0) : Time.parse(@env["HTTP_IF_MODIFIED_SINCE"])
          if htime == mtime
            @headers << Riddl::Header.new("Connection","close")
            @status = 304 # Not modified
            return []
          else
            fmt = @a[1] || begin
              mt = MIME::Types.type_for(path).first
              if mt.nil?
                'text/plain;charset=utf-8'
              else
                apx = ''
                if mt.ascii?
                  tstr = File.read(path,CharlockHolmes::EncodingDetector::DEFAULT_BINARY_SCAN_LEN)
                  apx = ';charset=' + CharlockHolmes::EncodingDetector.detect(tstr)[:encoding]
                end
                mt.to_s + apx
              end
            end
            return Riddl::Parameter::Complex.new('file',fmt,File.open(path,'r'))
          end
        end
        @status = 404
      end
    end
  end
end
