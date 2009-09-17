require 'mime/types'
require 'erb'

module Riddl
  module Utils
    class ERBServe < Riddl::Implementation
      def response
        if ::File.exists?(@a[0])
          rval = ERB.new(::File.read(@a[0]), 0, "%<>")
          Riddl::Parameter::Complex.new("file",MIME::Types.type_for(@a[0]).to_s,rval.result(binding))
        else
          @status = 404
          []
        end
      end  
    end
  end  
end  
