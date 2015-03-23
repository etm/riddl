require 'erb'

module Riddl
  module Utils

    class DocOverlay < Riddl::Implementation
      def response
        rval = ERB.new(File.read(File.dirname(__FILE__) + '/docoverlay.html'), 0, "%<>")
        Riddl::Parameter::Complex.new('documentationresponse','text/html',rval.result(binding))
      end
    end
      
  end
end
