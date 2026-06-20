require File.expand_path(File.dirname(__FILE__) + '/../../constants')
require File.expand_path(File.dirname(__FILE__) + '/../utils')
require 'stringio'

module Riddl
  module Protocols
    module HTTP

      class StreamingBody
        CHUNK_SIZE = 1 << 16  # 64 KiB

        def initialize(parts)
          @parts = parts
        end

        def each
          @parts.each do |part|
            if part.respond_to?(:read)
              part.rewind if part.respond_to?(:rewind)
              yield chunk while (chunk = part.read(CHUNK_SIZE))
            else
              yield part.to_s
            end
          end
        end

        def close
          @parts.each do |part|
            part.close if part.respond_to?(:close) && !part.is_a?(String)
          end
        end
      end

      class Generator
        def initialize(params,headers)
          @params = params
          @headers = headers
        end

        def self.merge(parts)
          parts.map do |p|
            if p.respond_to?(:read)
              p.rewind if p.respond_to?(:rewind)
              p.read
            else
              p.to_s
            end
          end.join
        end

        def generate(mode=:output)
          if @params.is_a?(Array) && @params.length == 1
            body(@params[0],mode)
          elsif @params.class == Riddl::Parameter::Simple || @params.class == Riddl::Parameter::Complex
            body(@params,mode)
          elsif @params.is_a?(Array) && @params.length > 1
            multipart(mode)
          else
            if mode == :output
              @headers['Content-Type'] = 'text/plain'
            end
            []
          end
        end

        def body(r,mode)
          parts = []
          case r
            when Riddl::Parameter::Simple
              if mode == :output
                parts << r.value
                @headers['Content-Type'] = 'text/plain'
                @headers['Content-ID'] = r.name
                @headers['RIDDL-TYPE'] = 'simple'
              else
                @headers['Content-Type'] = 'application/x-www-form-urlencoded'
                parts << Riddl::Protocols::Utils::escape(r.name) + '=' + Riddl::Protocols::Utils::escape(r.value)
              end
            when Riddl::Parameter::Complex
              parts << r.value
              @headers['Content-Type'] = r.mimetype + r.mimextra
              @headers['RIDDL-TYPE'] = 'complex'
              if r.filename.nil?
                @headers['Content-ID'] = r.name
              else
                @headers['Content-Disposition'] = "riddl-data; name=\"#{r.name}\"; filename=\"#{r.filename}\""
              end
          end
          parts
        end
        private :body

        def multipart(mode)
          parts = []
          scount = ccount = 0
          @params.each do |r|
            case r
              when Riddl::Parameter::Simple
                scount += 1
              when Riddl::Parameter::Complex
                ccount += 1
            end
          end
          if scount > 0 && ccount == 0
            @headers['Content-Type'] = 'application/x-www-form-urlencoded'
            res = []
            @params.each do |r|
              case r
                when Riddl::Parameter::Simple
                  res << Riddl::Protocols::Utils::escape(r.name) + '=' + Riddl::Protocols::Utils::escape(r.value)
              end
            end
            parts << res.join('&')
          else
            if scount + ccount > 0
              @headers['Content-Type'] = "multipart/#{mode == :input ? 'form-data' : 'mixed'}; boundary=\"#{BOUNDARY}\""
              @params.each do |r|
                case r
                  when Riddl::Parameter::Simple
                    parts << '--' + BOUNDARY + EOL +
                             'RIDDL-TYPE: simple' + EOL +
                             "Content-Disposition: form-data; name=\"#{r.name}\"" + EOL +
                             EOL +
                             r.value.to_s +
                             EOL
                  when Riddl::Parameter::Complex
                    parts << '--' +  BOUNDARY + EOL +
                             'RIDDL-TYPE: complex' + EOL +
                             "Content-Disposition: form-data; name=\"#{r.name}\"" +
                                (r.filename.nil? ? EOL : "; filename=\"#{r.filename}\"" + EOL) +
                             'Content-Transfer-Encoding: binary' + EOL +
                             'Content-Type: ' + r.mimetype + r.mimextra + EOL +
                             EOL
                    parts << r.value
                    parts << EOL
                end
              end
              parts << '--' + BOUNDARY + '--' + EOL
            end
          end
          parts
        end
        private :multipart

      end
    end
  end
end
