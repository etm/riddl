require File.expand_path(File.dirname(__FILE__) + '/../../constants')
require File.expand_path(File.dirname(__FILE__) + '/../utils')
require 'stringio'

module Riddl
  module Protocols
    module HTTP
      class Generator
        def initialize(params,headers)
          @params = params
          @headers = headers
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
              StringIO.new('','r+b')
            else
              StringIO.new('','r+b')
            end
          end
        end

        def body(r,mode)
          tmp = StringIO.new('','r+b')
          case r
            when Riddl::Parameter::Simple
              if mode == :output
                tmp.write r.value
                @headers['Content-Type'] = 'text/plain'
                @headers['Content-ID'] = r.name
                @headers['RIDDL-TYPE'] = 'simple'
              end
              if mode == :input
                @headers['Content-Type'] = 'application/x-www-form-urlencoded'
                tmp.write Riddl::Protocols::Utils::escape(r.name) + '=' + Riddl::Protocols::Utils::escape(r.value)
              end
            when Riddl::Parameter::Complex
              tmp.write(r.value.respond_to?(:read) ? r.value.read : r.value)
              @headers['Content-Type'] = r.mimetype + r.mimextra
              @headers['RIDDL-TYPE'] = 'complex'
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

        def multipart(mode)
          tmp = StringIO.new('','r+b')
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
            tmp.write res.join('&')
          else
            if scount + ccount > 0
              @headers['Content-Type'] = "multipart/#{mode == :input ? 'form-data' : 'mixed'}; boundary=\"#{BOUNDARY}\""
              @params.each do |r|
                case r
                  when Riddl::Parameter::Simple
                    tmp.write '--' + BOUNDARY + EOL
                    tmp.write 'RIDDL-TYPE: simple' + EOL
                    tmp.write "Content-Disposition: #{mode == :input ? 'form-data' : 'riddl-data'}; name=\"#{r.name}\"" + EOL
                    tmp.write EOL
                    tmp.write r.value
                    tmp.write EOL
                  when Riddl::Parameter::Complex
                    tmp.write '--' +  BOUNDARY + EOL
                    tmp.write 'RIDDL-TYPE: complex' + EOL
                    tmp.write "Content-Disposition: #{mode == :input ? 'form-data' : 'riddl-data'}; name=\"#{r.name}\""
                    #tmp.write r.filename.nil? ? '; filename=""' + EOL : "; filename=\"#{r.filename}\"" + EOL
                    tmp.write r.filename.nil? ? EOL : "; filename=\"#{r.filename}\"" + EOL
                    tmp.write 'Content-Transfer-Encoding: binary' + EOL
                    tmp.write 'Content-Type: ' + r.mimetype + r.mimextra + EOL
                    tmp.write EOL
                    tmp.write(r.value.respond_to?(:read) ? r.value.read : r.value)
                    tmp.write EOL
                end
              end
              tmp.write '--' + BOUNDARY + '--' + EOL
            end
          end
          tmp.flush
          tmp.rewind
          tmp
        end
        private :multipart

      end
    end
  end
end
