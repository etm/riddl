require ::File.dirname(__FILE__) + "/parameter"

module Riddl
  class HttpParser
    MULTIPART_CONTENT_TYPES = [
      #{{{
      'multipart/form-data',
      'multipart/related',
      'multipart/mixed'
      #}}}
    ]
    FORM_CONTENT_TYPES = [
      #{{{
      nil,
      'application/x-www-form-urlencoded'
      #}}}
    ]  
    EOL = "\r\n"
    D = '&;'

    def unescape(s)
      #{{{
      s.tr('+', ' ').gsub(/((?:%[0-9a-fA-F]{2})+)/n){
        [$1.delete('%')].pack('H*')
      }
      #}}}
    end
    private :unescape

    def parse_content(input,ctype,content_length,content_disposition,content_id)
      #{{{
      ctype = nil if ctype == 'text/riddl-data'
      filename = content_disposition[/ filename="?([^\";]*)"?/ni, 1]
      name = content_disposition[/ name="?([^\";]*)"?/ni, 1] || content_id

      if ctype || filename
        body = Parameter::Tempfile.new("RiddlMultipart")
        body.binmode if body.respond_to?(:binmode)
      else
        body = ''
      end
      
      bufsize = 16384
         
      until content_length <= 0
        c = input.read(bufsize < content_length ? bufsize : content_length)
        raise EOFError, "bad content body"  if c.nil? || c.empty?
        body << c
        content_length -= c.size
      end  

      add_to_params(name,body,filename,ctype,nil)
      #}}}
    end
    private :parse_content

    def parse_multipart(input,content_type,content_length)
      #{{{
      content_type =~ %r|\Amultipart/.*boundary=\"?([^\";,]+)\"?|n
      boundary = "--#{$1}"

      boundary_size = boundary.size + EOL.size
      content_length -= boundary_size
      status = input.read(boundary_size)
      raise EOFError, "bad content body" unless status == boundary + EOL

      rx = /(?:#{EOL})?#{Regexp.quote boundary}(#{EOL}|--)/n

      buf = ""
      bufsize = 16384
      loop do
        head = nil
        body = ''
        filename = ctype = name = nil

        until head && buf =~ rx
          if !head && i = buf.index(EOL+EOL)
            head = buf.slice!(0, i+2) # First \r\n
            buf.slice!(0, 2)          # Second \r\n

            filename = head[/Content-Disposition:.* filename="?([^\";]*)"?/ni, 1]
            ctype = head[/Content-Type: (.*)#{EOL}/ni, 1]
            name = head[/Content-Disposition:.*\s+name="?([^\";]*)"?/ni, 1] || head[/Content-ID:\s*([^#{EOL}]*)/ni, 1]

            if ctype || filename
              body = Parameter::Tempfile.new("RiddlMultipart")
              body.binmode  if body.respond_to?(:binmode)
            end

            next
          end

          # Save the read body part.
          if head && (boundary_size+4 < buf.size)
            body << buf.slice!(0, buf.size - (boundary_size+4))
          end

          c = input.read(bufsize < content_length ? bufsize : content_length)
          raise EOFError, "bad content body"  if c.nil? || c.empty?
          content_length -= c.size
          buf << c
        end

        # Save the rest.
        if i = buf.index(rx)
          body << buf.slice!(0, i)
          buf.slice!(0, boundary_size+2)
          content_length = -1  if $1 == "--"
        end

        add_to_params(name,body,filename,ctype,head)

        break if buf.empty? || content_length == -1
      end
      #}}}
    end
    private :parse_multipart

    def add_to_params(name,body,filename,ctype,head)
      #{{{
      if filename == ""
        # filename is blank which means no file has been selected
      elsif filename && ctype
        body.rewind

        # Take the basename of the upload's original filename.
        # This handles the full Windows paths given by Internet Explorer
        # (and perhaps other broken user agents) without affecting
        # those which give the lone filename.
        filename =~ /^(?:.*[:\\\/])?(.*)/m
        filename = $1

        @params << Parameter::Complex.new(name, ctype, body, filename, head)
      elsif !filename && ctype
        body.rewind
        
        # Generic multipart cases, not coming from a form
        @params << Parameter::Complex.new(name, ctype, body, nil, head)
      else
        @params << Parameter::Simple.new(name, body, :body)
      end
      #}}}
    end
    private :add_to_params

    def parse_nested_query(qs, type)
      #{{{
      (qs || '').split(/[#{D}] */n).each do |p|
        k, v = unescape(p).split('=', 2)
        @params << Parameter::Simple.new(k,v,type)
      end
      #}}}
    end
    private :parse_nested_query

    def initialize(query_string,input,content_type,content_length,content_disposition,content_id)
      #{{{
      # rewind because in some cases it is not at start (when multipart without length)
      begin
        input.rewind if input.respond_to?(:rewind)
      rescue Errno::ESPIPE
        # Handles exceptions raised by input streams that cannot be rewound
        # such as when using plain CGI under Apache
      end

      media_type = content_type && content_type.split(/\s*[;,]\s*/, 2).first.downcase
      @params = []
      parse_nested_query(query_string,:query)
      if MULTIPART_CONTENT_TYPES.include?(media_type)
        parse_multipart(input,content_type,content_length.to_i)
      elsif FORM_CONTENT_TYPES.include?(media_type)
        # sub is a fix for Safari Ajax postings that always append \0
        parse_nested_query(input.read.sub(/\0\z/, ''),:body)
      else 
        parse_content(input,content_type,content_length.to_i,content_disposition||'',content_id||'')
      end

      begin
        input.rewind if input.respond_to?(:rewind)
      rescue Errno::ESPIPE
        # Handles exceptions raised by input streams that cannot be rewound
        # such as when using plain CGI under Apache
      end
      #}}}
    end

    attr_reader :params
  end
end
