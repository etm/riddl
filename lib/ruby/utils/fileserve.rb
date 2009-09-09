require 'mime/types'

module Riddl
  module Utils
    class FileServe < Riddl::Implementation
      def response
        if ::File.directory?(@a[0])
          cur = @r[@m.length..-1]
          path = "#{@a[0]}/#{cur.join('/')}".gsub(/\/+/,'/')
          if ::File.directory?(path)
            return Riddl::Parameter::Complex.new("file","text/html","<b>W00t. It's a directory. Someone has to implement directory listing.</b>")
          end
          if ::File.exists?(path)
            return Riddl::Parameter::Complex.new("file",MIME::Types.type_for(path),::File.open(path,'r'))
          end
        end
        if ::File.exists?(@a[0])
          return Riddl::Parameter::Complex.new("file",MIME::Types.type_for(@a[0]),::File.open(@a[0],'r'))
        end
        @status = 404
      end  
    end
  end  
end  
