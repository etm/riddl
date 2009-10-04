require 'mime/types'
require 'erb'

module Riddl
  module Utils
    class ERBServe < Riddl::Implementation
      def response
        path = File.file?(@a[0]) ? @a[0] : "#{@a[0]}/#{@r[@m.length..-1].join('/')}".gsub(/\/+/,'/')
        if File.directory?(path)
          @status = 404
          return []
        end
        if File.exists?(path)
          __ERB_FILE__ = path
          rval = ERB.new(File.read(path), 0, "%<>")
          return Riddl::Parameter::Complex.new("data",MIME::Types.type_for(path).to_s,rval.result(binding))
        end
        @status = 404
        []
      end  
    end
  end  
end
