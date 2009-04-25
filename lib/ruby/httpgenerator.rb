module Riddl
  class HttpGenerator
    BOUNDARY = "Time_is_an_illusion._Lunchtime_doubly_so.0xriddldata"
    EOL = "\r\n"

    def initialize(params,res)
      @params = params
      @res = res
    end

    def read
      if @params.length == 1
        r = @params[0]
        case r.class
          when SimpleParameter
            @res.write r.value
            @res['Content-Type'] = "text/riddl-data"
            @res['Content-Disposition'] = "riddl-data; name=\"#{r.name}\""
          when ComplexParameter
            @res.write r.value.read
            @res['Content-Type'] = r.mimetype
            @res['Content-Disposition'] = "riddl-data; name=\"#{r.name}\""
            @res['Content-Disposition'] += "; filename=\"#{r.filename}\"" unless r.filename.nil?
        end   
      end
      if @params.length > 1
        @res['Content-Type'] = "multipart/mixed; boundary=\"#{BOUNDARY}\"#{EOL}"
        @params.each do |r|
          case r.class
            when SimpleParameter
              @res.write "--" + BOUNDARY + EOL
              @res.write "Content-Disposition: riddl-data; name=\"#{r.name}\"" + EOL
              @res.write EOL
              @res.write r.value
              @res.write EOL
            when ComplexParameter
              @res.write "--" +  BOUNDARY + EOL
              @res.write "Content-Disposition: riddl-data; name=\"#{r.name}\""
              @res.write if r.filename.nil?
                EOL
              else
                "; filename=\"#{r.filename}\"" + EOL
              end
              @res.write "Content-Transfer-Encoding: binary" + EOL
              @res.write "Content-Type: " + r.mimetype + EOL
              @res.write EOL
              @res.write r.value.read
              @res.write EOL
            end  
          end   
        end
        @res.write "--" + BOUNDARY + EOL
      end  
    end
  end
end
