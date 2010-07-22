require 'net/http'
require 'socket'
require 'uri'
require 'openssl'
require 'digest/md5'
require File.expand_path(File.dirname(__FILE__) + '/wrapper')
require File.expand_path(File.dirname(__FILE__) + '/error')
require File.expand_path(File.dirname(__FILE__) + '/httpgenerator')
require File.expand_path(File.dirname(__FILE__) + '/httpparser')
require File.expand_path(File.dirname(__FILE__) + '/header')

unless Module.constants.include?('CLIENT_INCLUDED')
  CLIENT_INCLUDED = true

  module Riddl

    class Client
      #{{{
      def initialize(base, riddl=nil)
        @base = base.nil? ? '' : base.gsub(/\/+$/,'')
        @wrapper = nil
        unless riddl.nil?
          @wrapper = (riddl.class == Riddl::Wrapper ? riddl : Riddl::Wrapper::new(riddl))
          raise SpecificationError, 'No RIDDL description or declaration found.' if !@wrapper.description? && !@wrapper.declaration?
          raise SpecificationError, 'RIDDL does not conform to specification' unless @wrapper.validate!
          @wrapper.load_necessary_handlers!
        end
      end
      attr_reader :base

      def self::location(base)
        new(base)
      end
      def self::interface(base,riddl)
        new(base,riddl)
      end
      def self::facade(riddl)
        new(nil,riddl)
      end

      def resource(path="")
        Resource.new(@base,@wrapper,path)
      end
      def get(parameters = []);    resource('/').get(parameters);    end
      def post(parameters = []);   resource('/').post(parameters);   end
      def put(parameters = []);    resource('/').put(parameters);    end
      def delete(parameters = []); resource('/').delete(parameters); end
      def request(what)            resource('/').request(what);      end
      #}}}

      class WebSocket# {{{
        class << self
            attr_accessor(:debug)
        end

        class Error < RuntimeError

        end

        def initialize(arg, params = {})
          if params[:server] # server

            @server = params[:server]
            @socket = arg
            line = gets().chomp()
            if !(line =~ /\AGET (\S+) HTTP\/1.1\z/n)
              raise(WebSocket::Error, "invalid request: #{line}")
            end
            @path = $1
            read_header()
            if !@header["Sec-WebSocket-Key1"] || !@header["Sec-WebSocket-Key2"]
              raise(WebSocket::Error,
                "Client speaks old WebSocket protocol, " +
                "missing header Sec-WebSocket-Key1 and Sec-WebSocket-Key2")
            end
            @key3 = read(8)
            if !@server.accepted_origin?(self.origin)
              raise(WebSocket::Error,
                ("Unaccepted origin: %s (server.accepted_domains = %p)\n\n" +
                  "To accept this origin, write e.g. \n" +
                  "  WebSocketServer.new(..., :accepted_domains => [%p]), or\n" +
                  "  WebSocketServer.new(..., :accepted_domains => [\"*\"])\n") %
                [self.origin, @server.accepted_domains, @server.origin_to_domain(self.origin)])
            end
            @handshaked = false

          else # client

            uri = arg.is_a?(String) ? URI.parse(arg) : arg

            if uri.scheme == "ws"
              default_port = 80
            elsif uri.scheme = "wss"
              default_port = 443
            else
              raise(WebSocket::Error, "unsupported scheme: #{uri.scheme}")
            end

            @path = (uri.path.empty? ? "/" : uri.path) + (uri.query ? "?" + uri.query : "")
            host = uri.host + (uri.port == default_port ? "" : ":#{uri.port}")
            origin = params[:origin] || "http://#{uri.host}"
            key1 = generate_key()
            key2 = generate_key()
            key3 = generate_key3()

            socket = TCPSocket.new(uri.host, uri.port || default_port)

            if uri.scheme == "ws"
              @socket = socket
            else
              @socket = ssl_handshake(socket)
            end

            write(
              "GET #{@path} HTTP/1.1\r\n" +
              "Upgrade: WebSocket\r\n" +
              "Connection: Upgrade\r\n" +
              "Host: #{host}\r\n" +
              "Origin: #{origin}\r\n" +
              "Sec-WebSocket-Key1: #{key1}\r\n" +
              "Sec-WebSocket-Key2: #{key2}\r\n" +
              "\r\n" +
              "#{key3}")
            flush()

            line = gets().chomp()
            raise(WebSocket::Error, "bad response: #{line}") if !(line =~ /\AHTTP\/1.1 101 /n)
            read_header()
            if @header["Sec-WebSocket-Origin"] != origin
              raise(WebSocket::Error,
                "origin doesn't match: '#{@header["WebSocket-Origin"]}' != '#{origin}'")
            end
            reply_digest = read(16)
            expected_digest = security_digest(key1, key2, key3)
            if reply_digest != expected_digest
              raise(WebSocket::Error,
                "security digest doesn't match: %p != %p" % [reply_digest, expected_digest])
            end
            @handshaked = true

          end
          @received = []
          @buffer = ""
          @closing_started = false
        end

        attr_reader(:server, :header, :path)

        def handshake(status = nil, header = {})
          if @handshaked
            raise(WebSocket::Error, "handshake has already been done")
          end
          status ||= "101 Web Socket Protocol Handshake"
          def_header = {
            "Sec-WebSocket-Origin" => self.origin,
            "Sec-WebSocket-Location" => self.location,
          }
          header = def_header.merge(header)
          header_str = header.map(){ |k, v| "#{k}: #{v}\r\n" }.join("")
          digest = security_digest(
            @header["Sec-WebSocket-Key1"], @header["Sec-WebSocket-Key2"], @key3)
          # Note that Upgrade and Connection must appear in this order.
          write(
            "HTTP/1.1 #{status}\r\n" +
            "Upgrade: WebSocket\r\n" +
            "Connection: Upgrade\r\n" +
            "#{header_str}\r\n#{digest}")
          flush()
          @handshaked = true
        end

        def send(data)
          if !@handshaked
            raise(WebSocket::Error, "call WebSocket\#handshake first")
          end
          data = force_encoding(data.dup(), "ASCII-8BIT")
          write("\x00#{data}\xff")
          flush()
        end

        def receive()
          if !@handshaked
            raise(WebSocket::Error, "call WebSocket\#handshake first")
          end
          packet = gets("\xff")
          return nil if !packet
          if packet =~ /\A\x00(.*)\xff\z/nm
            return force_encoding($1, "UTF-8")
          elsif packet == "\xff" && read(1) == "\x00" # closing
            if @server
              @socket.close()
            else
              close()
            end
            return nil
          else
            raise(WebSocket::Error, "input must be either '\\x00...\\xff' or '\\xff\\x00'")
          end
        end

        def tcp_socket
          return @socket
        end

        def host
          return @header["Host"]
        end

        def origin
          return @header["Origin"]
        end

        def location
          return "ws://#{self.host}#{@path}"
        end
        
        # Does closing handshake.
        def close()
          return if @closing_started
          write("\xff\x00")
          @socket.close() if !@server
          @closing_started = true
        end
        
        def close_socket()
          @socket.close()
        end

      private

        NOISE_CHARS = ("\x21".."\x2f").to_a() + ("\x3a".."\x7e").to_a()

        def read_header()
          @header = {}
          while line = gets()
            line = line.chomp()
            break if line.empty?
            if !(line =~ /\A(\S+): (.*)\z/n)
              raise(WebSocket::Error, "invalid request: #{line}")
            end
            @header[$1] = $2
          end
          if @header["Upgrade"] != "WebSocket"
            raise(WebSocket::Error, "invalid Upgrade: " + @header["Upgrade"])
          end
          if @header["Connection"] != "Upgrade"
            raise(WebSocket::Error, "invalid Connection: " + @header["Connection"])
          end
        end

        def gets(rs = $/)
          line = @socket.gets(rs)
          $stderr.printf("recv> %p\n", line) if WebSocket.debug
          return line
        end

        def read(num_bytes)
          str = @socket.read(num_bytes)
          $stderr.printf("recv> %p\n", str) if WebSocket.debug
          return str
        end

        def write(data)
          if WebSocket.debug
            data.scan(/\G(.*?(\n|\z))/n) do
              $stderr.printf("send> %p\n", $&) if !$&.empty?
            end
          end
          @socket.write(data)
        end

        def flush()
          @socket.flush()
        end

        def security_digest(key1, key2, key3)
          bytes1 = websocket_key_to_bytes(key1)
          bytes2 = websocket_key_to_bytes(key2)
          return Digest::MD5.digest(bytes1 + bytes2 + key3)
        end

        def generate_key()
          spaces = 1 + rand(12)
          max = 0xffffffff / spaces
          number = rand(max + 1)
          key = (number * spaces).to_s()
          (1 + rand(12)).times() do
            char = NOISE_CHARS[rand(NOISE_CHARS.size)]
            pos = rand(key.size + 1)
            key[pos...pos] = char
          end
          spaces.times() do
            pos = 1 + rand(key.size - 1)
            key[pos...pos] = " "
          end
          return key
        end

        def generate_key3()
          return [rand(0x100000000)].pack("N") + [rand(0x100000000)].pack("N")
        end

        def websocket_key_to_bytes(key)
          num = key.gsub(/[^\d]/n, "").to_i() / key.scan(/ /).size
          return [num].pack("N")
        end

        def force_encoding(str, encoding)
          if str.respond_to?(:force_encoding)
            return str.force_encoding(encoding)
          else
            return str
          end
        end

        def ssl_handshake(socket)
          ssl_context = OpenSSL::SSL::SSLContext.new()
          ssl_socket = OpenSSL::SSL::SSLSocket.new(socket, ssl_context)
          ssl_socket.sync_close = true
          ssl_socket.connect()
          return ssl_socket
        end
      end# }}}

      class Resource
        #{{
        def initialize(base,wrapper,path)
          #{{{
          @base = base
          @wrapper = wrapper
          @rpath = "/#{path}".gsub(/\/+/,'/')
          @path = if @wrapper.nil?
            @rpath
          else
            @path = @wrapper.paths.find{ |e| e[1] =~ @rpath }
            raise PathError, 'Path not found.' if @path.nil?
            @path[0]
          end
          @rpath = @rpath == '/' ? '' : @rpath 
          #}}}
        end
        attr_reader :rpath

        def get(parameters = [])
          exec_request('GET',parameters)
        end
        def post(parameters = [])
          exec_request('POST',parameters)
        end
        def put(parameters = [])
          exec_request('PUT',parameters)
        end
        def delete(parameters = [])
          exec_request('DELETE',parameters)
        end
        def request(what)
          #{{{
          if what.class == Hash && what.length == 1
            what.each do |method,parameters|
              return exec_request(method.to_s.upcase,parameters)
            end
          end
          raise ArgumentError, "Hash with ONE method => parameters pair required"
          #}}}
        end

        def extract_headers(parameters)
          #{{{
          headers = {}
          parameters.delete_if do |p|
            if p.class == Riddl::Header
              headers[p.name.upcase] = "#{p.value}"
              true
            else
              false
            end
          end
          headers
          #}}}
        end
        private :extract_headers
        def extract_response_headers(headers)
          #{{{
          ret = {}
          headers.each do |k,v|
            if v.nil?
              ret[k.name.upcase.gsub(/\-/,'_')] = v
            else  
              ret[k.upcase.gsub(/\-/,'_')] = v
            end  
          end
          ret
          #}}}
        end
        private :extract_headers
        
        def extract_qparams(parameters)
          #{{{
          qparams = []
          parameters.delete_if do |p|
            if p.class == Riddl::Parameter::Simple && p.type == :query
              qparams << HttpGenerator::escape(p.name) + (p.value.nil? ? '' : '=' + HttpGenerator::escape(p.value))
              true
            else
              false
            end
          end
          qparams
          #}}}
        end
        private :extract_qparams

        def merge_paths(int,real)
          t = int.top.sub(/^\/*/,'').split('/')
          real = real.sub(/^\/*/,'').split('/')
          real = real[t.length..-1]
          base = int.base == '' ? @base : int.base
          base + '/' + real.join('/')
        end
        private :merge_paths

        def exec_request(riddl_method,parameters)
          headers = extract_headers(parameters)

          unless @wrapper.nil?
            riddl_message = @wrapper.io_messages(@path,riddl_method.downcase,parameters,headers)
            if riddl_message.nil?
              raise InputError, "Not a valid input to service."
            end
          end

          qparams = extract_qparams(parameters)

          if @wrapper.nil? || @wrapper.description?
            res, response = make_request(@base + @rpath,riddl_method,parameters,headers,qparams)
            if !@wrapper.nil? && res.code.to_i == 200
              unless @wrapper.check_message(response,res,riddl_message.out)
                raise OutputError, "Not a valid output from service."
              end
            end
            return res.code.to_i, response, extract_response_headers(res)
          end

          if !@wrapper.nil? && @wrapper.declaration?
            headers['Riddl-Declaration-Path'] = @rpath
            if riddl_message.route.nil?
              reqp = merge_paths(riddl_message.interface,@rpath)
              res, response = make_request(reqp,riddl_method,parameters,headers,qparams)
              if res.code.to_i == 200
                unless @wrapper.check_message(response,res,riddl_message.out)
                  raise OutputError, "Not a valid output from service."
                end
              end  
              return res.code.to_i, response, extract_response_headers(res)
            else
              tp = parameters
              th = headers
              tq = qparams
              riddl_message.route.each do |m|
                reqp = merge_paths(m.interface,@rpath)
                res, response = make_request(reqp,riddl_method,tp,th,tq)
                if res.code.to_i != 200 || !@wrapper.check_message(response,res,m.out)
                  raise OutputError, "Not a valid output from service."
                end
                unless m == riddl_message.route.last
                  tp = response
                  th = extract_headers(response) # TODO extract relvant headers from res (get from m.out)
                  tq = extract_qparams(response)
                end
              end
              return res.code.to_i, response, extract_response_headers(res)
            end
          end
        end
        private :exec_request

        def make_request(url,riddl_method,parameters,headers,qparams)
          #{{{
          url = URI.parse(url)
          qs = qparams.join('&')
          req = Riddl::Client::Request.new(riddl_method,url.path,parameters,headers,qs)
          res = response = nil

          Net::HTTP.start(url.host, url.port) do |http|
            http.request(req) do |res|
              bs = Parameter::Tempfile.new("RiddlBody")
              res.read_body(bs)
              bs.rewind
              response = Riddl::HttpParser.new(
                "",
                bs,
                res['CONTENT-TYPE'],
                res['CONTENT-LENGTH'],
                res['CONTENT-DISPOSITION'],
                res['CONTENT-ID'],
                res['RIDDL-TYPE']
              ).params
            end
          end
          return res, response
          #}}}
        end
        private :make_request
        #}}}
      end

      class Request < Net::HTTPGenericRequest
        #{{{
        def initialize(method, path, parameters, headers, qs)
          path = (path.strip == '' ? '/' : path)
          path += "?#{qs}" unless qs == ''
          super method, true, true, path, headers
          tmp = HttpGenerator.new(parameters,self).generate(:input)
          self.content_length = tmp.size
          self.body_stream = tmp
        end
        #}}}
      end
    end

  end

end
