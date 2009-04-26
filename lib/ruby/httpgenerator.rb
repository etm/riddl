module Riddl
  class HttpGenerator
    BOUNDARY = "Time_is_an_illusion._Lunchtime_doubly_so.0xriddldata"
    EOL = "\r\n"

    def initialize(params,res)
      @params = params
      @res = res
    end

    def generate
      if @params.class == Array && @params.length == 1
        body(@params[0])
      end
      if @params.class == Riddl::Parameter::Simple || @params.class == Riddl::Parameter::Complex
        body(@params)
      end
      if @params.class == Array && @params.length > 1
        multipart
      end  
    end

    def body(r)
      case r
        when Riddl::Parameter::Simple
          @res.write r.value
          @res['Content-Type'] = "text/riddl-data"
          @res['Content-Disposition'] = "riddl-data; name=\"#{r.name}\""
        when Riddl::Parameter::Complex
          @res.write(r.value.class == IO ? r.value.read : r.value)
          @res['Content-Type'] = r.mimetype
          if r.filename.nil?
            @res['Content-ID'] = r.name
          else
            @res['Content-Disposition'] = "riddl-data; name=\"#{r.name}\"; filename=\"#{r.filename}\""
          end  
      end   
    end
    private :body

    def multipart
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
            @res.write r.filename.nil? ? EOL : "; filename=\"#{r.filename}\"" + EOL
            @res.write "Content-Transfer-Encoding: binary" + EOL
            @res.write "Content-Type: " + r.mimetype + EOL
            @res.write EOL
            @res.write r.value.read
            @res.write EOL
        end   
      end
      @res.write "--" + BOUNDARY + EOL
    end
    private :multipart
  
  end
end
