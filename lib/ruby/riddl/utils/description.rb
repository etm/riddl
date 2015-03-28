require File.expand_path(File.dirname(__FILE__) + '/../client')

module Riddl
  module Utils
    module Description

      class RDR < Riddl::Implementation
        def response
          @headers << Riddl::Header.new("RIDDL_DESCRIPTION", 'oh my, a riddl description')
          return Riddl::Parameter::Complex.new("riddl-description","text/xml",@a[0])
        end
      end

      class Call < Riddl::Implementation
        def response
          client = Riddl::Client.new @a[3]

          path = client.resource "/" + @a[4]
          @status, result, headers = if @a[0].nil?
            path.request @m => [ Riddl::Header.new("RIDDL_DECLARATION_RESOURCE", @a[2]), Riddl::Header.new("RIDDL-DECLARATION-PATH", @a[1]) ] + @h.map{|a,b| Riddl::Header.new(a,b)} + @p
          else 
            path.request @m => [ Riddl::Header.new("RIDDL_DECLARATION_RESOURCE", @a[2]), Riddl::Header.new("RIDDL-DECLARATION-PATH", @a[1]) ] + @a[0].headers.map{|a,b| Riddl::Header.new(a,b)} + @a[0].response
          end
          headers.each do |k,v|
            @headers << Riddl::Header.new(k,v) unless ["CONTENT_TYPE", "CONTENT_DISPOSITION", "RIDDL_TYPE", "CONTENT_ID", "CONTENT_LENGTH", "CONNECTION", "SERVER"].include?(k)
          end
          result
        end
      end
      
    end
  end
end
