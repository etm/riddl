require File.expand_path(File.dirname(__FILE__) + '/../client')

module Riddl
  module Utils
    module Description

      class XML < Riddl::Implementation
        def response
          return Riddl::Parameter::Complex.new("riddl-description","text/xml",@a[0])
        end
      end

      class Call < Riddl::Implementation
        def response
          client = Riddl::Client.new(@a[3],@a[4])

          path = client.resource "/" + @a[5]
          @status, result = if @a[0].nil?
            path.request @m => [ Riddl::Header.new("RIDDL_DECLARATION_RESOURCE", @a[2]), Riddl::Header.new("RIDDL-DECLARATION-PATH", @a[1]) ] + @h.map{|a,b| Riddl::Header.new(a,b)} + @p
          else 
            path.request @m => [ Riddl::Header.new("RIDDL_DECLARATION_RESOURCE", @a[2]), Riddl::Header.new("RIDDL-DECLARATION-PATH", @a[1]) ] + @a[0].headers.map{|a,b| Riddl::Header.new(a,b)} + @a[0].response
          end  
          result
        end
      end
      
    end
  end
end
