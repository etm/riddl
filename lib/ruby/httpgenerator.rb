require 'stringio'

module Riddl
  class HttpGenerator
    BOUNDARY = "Time_is_an_illusion._Lunchtime_doubly_so.0xriddldata"
    EOL = "\r\n"

    def initialize(params,headers)
      @params = params
      @headers = headers
    end

    def generate
      if @params.class == Array && @params.length == 1
        body(@params[0])
      elsif @params.class == Riddl::Parameter::Simple || @params.class == Riddl::Parameter::Complex
        body(@params)
      elsif @params.class == Array && @params.length > 1
        multipart
      else
        StringIO.new('r+b')
      end  
    end

    def body(r)
      tmp = StringIO.new('r+b')
      case r
        when Riddl::Parameter::Simple
          tmp.write r.value
          @headers['Content-Type'] = 'text/riddl-data'
          @headers['Content-Disposition'] = "riddl-data; name=\"#{r.name}\""
        when Riddl::Parameter::Complex
          tmp.write(r.value.respond_to?(:read) ? r.value.read : r.value)
          @headers['Content-Type'] = r.mimetype
          if r.filename.nil?
            @headers['Content-ID'] = r.name
          else
            @headers['Content-Disposition'] = "riddl-data; name=\"#{r.name}\"; filename=\"#{r.filename}\""
          end  
      end
      tmp.flush
      tmp.rewind
      tmp
    end
    private :body

    def multipart
      tmp = StringIO.new('r+b')
      @headers['Content-Type'] = "multipart/mixed; boundary=\"#{BOUNDARY}\""
      @params.each do |r|
        case r
          when Riddl::Parameter::Simple
            tmp.write "--" + BOUNDARY + EOL
            tmp.write "Content-Disposition: riddl-data; name=\"#{r.name}\"" + EOL
            tmp.write EOL
            tmp.write r.value
            tmp.write EOL
          when Riddl::Parameter::Complex
            tmp.write "--" +  BOUNDARY + EOL
            tmp.write "Content-Disposition: riddl-data; name=\"#{r.name}\""
            tmp.write r.filename.nil? ? EOL : "; filename=\"#{r.filename}\"" + EOL
            tmp.write "Content-Transfer-Encoding: binary" + EOL
            tmp.write "Content-Type: " + r.mimetype + EOL
            tmp.write EOL
            tmp.write r.value.read
            tmp.write EOL
        end   
      end
      tmp.write "--" + BOUNDARY + EOL
      tmp.flush
      tmp.rewind
      tmp
    end
    private :multipart
  
  end
end
