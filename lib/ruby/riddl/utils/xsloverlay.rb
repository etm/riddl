module Riddl
  module Utils

    class XSLOverlay < Riddl::Implementation
      def response
        doc = if @p[0].value.class == String 
          XML::Smart::string(@p[0].value)
        elsif @p[0].value.respond_to?(:read)
          XML::Smart::string(@p[0].value.read)
        else
          nil
        end
        unless doc.nil?
          doc.root.add_before "?xml-stylesheet", "href='#{@a[0]}' type='text/xsl'"
          Riddl::Parameter::Complex.new("content",@p[0].mimetype,doc.to_s)
        end  
      end
    end
      
  end
end
