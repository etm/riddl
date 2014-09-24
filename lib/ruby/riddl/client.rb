require 'rubygems'
require 'net/https'
require 'eventmachine'
require 'em-websocket-client'
require 'blather/client/client'
require 'uri'
require 'openssl'
require 'digest/md5'
require File.expand_path(File.dirname(__FILE__) + '/wrapper')
require File.expand_path(File.dirname(__FILE__) + '/error')
require File.expand_path(File.dirname(__FILE__) + '/protocols/http/generator')
require File.expand_path(File.dirname(__FILE__) + '/protocols/http/parser')
require File.expand_path(File.dirname(__FILE__) + '/protocols/xmpp/generator')
require File.expand_path(File.dirname(__FILE__) + '/protocols/xmpp/parser')
require File.expand_path(File.dirname(__FILE__) + '/protocols/utils')
require File.expand_path(File.dirname(__FILE__) + '/header')
require File.expand_path(File.dirname(__FILE__) + '/option')

class StringIO #{{{
  def continue_timeout; nil; end
end #}}}

class SignalWait #{{{
  def initialize 
    @q = Queue.new
  end

  def wait(num=1)
    num.times{ @q.deq }
  end

  def continue
    @q.push nil
  end
end #}}}

unless Module.constants.include?('CLIENT_INCLUDED')
  CLIENT_INCLUDED = true

  module Riddl

    # URL PATTERN
    #{{{
    RIDDL_URL_PATTERN = %r{
      \A

      # protocol identifier
      (?:(?:https?|xmpp)://)

      # user:pass authentication
      (?:\S+(?::\S*)?@)?

      (?:
        # IP address dotted notation octets
        # excludes loopback network 0.0.0.0
        # excludes reserved space >= 224.0.0.0
        # excludes network & broacast addresses
        # (first & last IP address of each class)
        (?:[1-9]\d?|1\d\d|2[01]\d|22[0-3])
        (?:\.(?:1?\d{1,2}|2[0-4]\d|25[0-5])){2}
        (?:\.(?:[1-9]\d?|1\d\d|2[0-4]\d|25[0-4]))
      |
        # host name
        (?:(?:[a-z\u00a1-\uffff0-9]+-?)*[a-z\u00a1-\uffff0-9]+)

        # domain name
        (?:\.(?:[a-z\u00a1-\uffff0-9]+-?)*[a-z\u00a1-\uffff0-9]+)*

        # TLD identifier
        (?:\.(?:[a-z\u00a1-\uffff]{2,}))
      |
        localhost
      )

      # port number
      (?::\d{2,5})?

      # resource path
      (?:/[^\s]*)?

      \z
    }xi
    #}}}

    class Client
      #{{{
      def initialize(base, riddl=nil, options={})
        @base = base.nil? ? '' : base.gsub(/\/+$/,'')
        @options = options
        @wrapper = nil
        if @base !~ RIDDL_URL_PATTERN
          raise ConnectionError, 'An RFC 3986 URI as target is required. Pro tip: (http|https|xmpp)://...'
        end
        if URI.parse(@base).scheme == 'xmpp' && !((@options[:jid] && @options[:pass]) || @options[:xmpp].is_a?(Blather::Client))
          raise ConnectionError, 'XMPP connections need jid/pass or Blather::client object passed as options to be successful.'
        end  
        if URI.parse(@base).scheme == 'xmpp' && @options[:jid] && @options[:pass]
          sig = SignalWait.new
          Thread::abort_on_exception = true
          Thread.new do
            begin
              EM.send EM.reactor_running? ? :defer : :run do
                client = Blather::Client.setup @options[:jid], @options[:pass]
                client.register_handler(:ready) { sig.continue }
                client.connect
                @options[:xmpp] = client
                sig.continue
              end
            rescue
              raise ConnectionError, 'XMPP connection not successful.'
            end  
          end
          sig.wait 2
        end
        unless riddl.nil?
          @wrapper = (riddl.class == Riddl::Wrapper ? riddl : Riddl::Wrapper::new(riddl))
          if @wrapper.declaration? && !base.nil?
            @wrapper = @wrapper.declaration.description
          end
          raise SpecificationError, 'No RIDDL description or declaration found.' if !@wrapper.description? && !@wrapper.declaration?
          raise SpecificationError, 'RIDDL does not conform to specification' unless @wrapper.validate!
          @wrapper.load_necessary_handlers!
          @wrapper.load_necessary_roles!
        end
      end
      attr_reader :base

      def close_xmpp
        @options[:xmpp].close if @options[:xmpp]
      end

      def self::location(base,options={})
        new(base,nil,options)
      end
      def self::interface(base,riddl,options={})
        new(base,riddl,options)
      end
      def self::facade(riddl,options={})
        new(nil,riddl,options)
      end

      def resource(path="")
        Resource.new(@base,@wrapper,path,@options)
      end
      def get(parameters = []);             resource.get(parameters);             end
      def simulate_get(parameters = []);    resource.simulate_get(parameters);    end
      def post(parameters = []);            resource.post(parameters);            end
      def simulate_post(parameters = []);   resource.simulate_post(parameters);   end
      def put(parameters = []);             resource.put(parameters);             end
      def simulate_put(parameters = []);    resource.simulate_put(parameters);    end
      def delete(parameters = []);          resource.delete(parameters);          end
      def simulate_delete(parameters = []); resource.simulate_delete(parameters); end
      def request(what)                     resource.request(what);               end
      def simulate_request(what)            resource.simulate_request(what);      end
      def ws(blk)                           resource.ws(blk);                     end
      #}}}

      class Resource
        def initialize(base,wrapper,path,options) #{{{
          @base = base
          @wrapper = wrapper
          @rpath = "/#{path}".gsub(/\/+/,'/')
          @options = options
          @path = if @wrapper.nil?
            @rpath
          else
            @path = @wrapper.paths.find{ |e| e[1] =~ @rpath }
            raise PathError, 'Path not found.' if @path.nil?
            @path[0]
          end
          @rpath = @rpath == '/' ? '' : @rpath 
        end #}}}
        attr_reader :rpath

        def ws(&blk) #{{{
          EM.run do
            conn = EventMachine::WebSocketClient.connect((@base + @rpath).sub(/^http/,'ws'))

            conn.disconnect do
              EM::stop_event_loop
            end

            if @options[:debug]
              conn.errback do |e|
                @options[:debug].puts "WS ERROR: #{e}"
              end
            end

            blk.call(conn)
          end   
        end #}}}

        def get(parameters = []) #{{{
          exec_request('GET',parameters,false)
        end #}}}
        def simulate_get(parameters = []) #{{{
          exec_request('GET',parameters,true)
        end #}}}
        
        def post(parameters = []) #{{{
          exec_request('POST',parameters,false)
        end #}}}
        def simulate_post(parameters = []) #{{{
          exec_request('POST',parameters,true)
        end #}}}

        def put(parameters = []) #{{{
          exec_request('PUT',parameters,false)
        end #}}}
        def simulate_put(parameters = []) #{{{
          exec_request('PUT',parameters,true)
        end #}}}

        def delete(parameters = []) #{{{
          exec_request('DELETE',parameters,false)
        end #}}}
        def simulate_delete(parameters = []) #{{{
          exec_request('DELETE',parameters,true)
        end #}}}

        def request(what) #{{{
          priv_request(what,false)
        end #}}}
        def simulate_request(what) #{{{
          priv_request(what,true)
        end #}}}
        def priv_request(what,simulate) #{{{
          if what.class == Hash && what.length == 1
            what.each do |method,parameters|
              return exec_request(method.to_s.upcase,parameters,simulate)
            end
          end
          raise ArgumentError, "Hash with ONE method => parameters pair required"
        end #}}} 
        private :priv_request

        def extract_options(parameters) #{{{
          options = {}
          parameters.delete_if do |p|
            if p.class == Riddl::Option
              options[p.name] = "#{p.value}"
              true
            else
              false
            end
          end
          options
        end #}}}
        private :extract_options
        def extract_headers(parameters) #{{{
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
        end #}}}
        private :extract_headers
        
        def extract_qparams(parameters,method) #{{{
          qparams = []
          starting = true
          parameters.delete_if do |p|
            if starting && p.class == Riddl::Parameter::Simple && method == 'get'
               p.type = :query
            end
            if p.class == Riddl::Parameter::Simple && p.type == :query
              qparams << Protocols::Utils::escape(p.name) + (p.value.nil? ? '' : '=' + Protocols::Utils::escape(p.value))
              true
            else
              starting = false
              false
            end
          end
          qparams
        end #}}}
        private :extract_qparams

        def exec_request(riddl_method,parameters,simulate) #{{{
          parameters = [ parameters ] unless parameters.is_a? Array
          parameters = parameters.dup
          headers = extract_headers(parameters)
          options = extract_options(parameters)
          role = nil

          unless @wrapper.nil?
            role = @wrapper.role(@path)
            if Riddl::Roles::roles[role]
              Riddl::Roles::roles[role]::before(@base + @rpath,riddl_method.downcase,parameters,headers,options) if Riddl::Roles::roles[role].respond_to?(:before)
            end  
            riddl_message = @wrapper.io_messages(@path,riddl_method.downcase,parameters,headers)
            if riddl_message.nil?
              raise InputError, "Not a valid input to service."
            end
          end

          qparams = extract_qparams(parameters,riddl_method.downcase)

          res = response = nil
          if @wrapper.nil? || @wrapper.description? || (@wrapper.declaration? && !@base.nil?)
            status, response, response_headers = make_request(@base + @rpath,riddl_method,parameters,headers,qparams,simulate,riddl_message && riddl_message.out ? true : false)
            return response if simulate
            if !@wrapper.nil? && status >= 200 && status < 300
              unless @wrapper.check_message(response,response_headers,riddl_message.out)
                raise OutputError, "Not a valid output from service."
              end
            end
          elsif !@wrapper.nil? && @base.nil? && @wrapper.declaration?
            headers['RIDDL-DECLARATION-PATH'] = @rpath
            if !riddl_message.route?
              status, response, response_headers = make_request(riddl_message.interface.real_url(@rpath,@base),riddl_method,parameters,headers,qparams,simulate,riddl_message && riddl_message.out ? true : false)
              return response if simulate
              if status >= 200 && status < 300
                unless @wrapper.check_message(response,response_headers,riddl_message.out)
                  raise OutputError, "Not a valid output from service."
                end
              end  
            else
              tp = parameters
              th = headers
              tq = qparams
              riddl_message.route.each do |m|
                if m == riddl_message.route.last
                  status, response, response_headers = make_request(m.interface.real_url(@rpath,@base),riddl_method,tp,th,tq,simulate,riddl_message && riddl_message.out ? true : false)
                else
                  status, response, response_headers = make_request(m.interface.real_url(@rpath,@base),riddl_method,tp,th,tq,simulate,true)
                end  
                return response if simulate
                if status < 200 || status >= 300 || !@wrapper.check_message(response,response_headers,m.out)
                  raise OutputError, "Not a valid output from service."
                end
                unless m == riddl_message.route.last
                  tp = response
                  th = extract_headers(response) # TODO extract relvant headers from res (get from m.out)
                  tq = extract_qparams(response,riddl_method.downcase)
                end
              end
            end
          else
            raise OutputError, "Impossible Error :-)"
          end
          unless role.nil?
            if Riddl::Roles::roles[role]
              response = Riddl::Roles::roles[role]::after(@base + @rpath,riddl_method.downcase,status,response,response_headers,options) if Riddl::Roles::roles[role].respond_to?(:after)
            end  
          end  
          return status, response, response_headers
        end #}}}
        private :exec_request

        def make_request(url,riddl_method,parameters,headers,qparams,simulate,ack) #{{{
          url = URI.parse(url)
          qs = qparams.join('&')
          if url.class == URI::HTTP || url.class == URI::HTTPS
            #{{{ 
            req = Riddl::Client::HTTPRequest.new(riddl_method,url.path,parameters,headers,qs)
            return req.simulate if simulate

            res = response = nil

            http = Net::HTTP.new(url.host, url.port)
            if url.class == URI::HTTPS
              http.use_ssl = true
              http.verify_mode = OpenSSL::SSL::VERIFY_NONE
            end  
            deb = nil
            if @options[:debug]
              http.set_debug_output @options[:debug]
            end  
            http.start do
              retrycount = 0
              begin
                http.request(req) do |resp|
                  res = resp
                  bs = Parameter::Tempfile.new("RiddlBody")
                  res.read_body(bs)
                  bs.rewind
                  response = Riddl::Protocols::HTTP::Parser.new(
                    "",
                    bs,
                    res['CONTENT-TYPE'],
                    res['CONTENT-LENGTH'],
                    res['CONTENT-DISPOSITION'],
                    res['CONTENT-ID'],
                    res['RIDDL-TYPE']
                  ).params
                end
              rescue => e
                retrycount += 1
                if retrycount < 4
                  retry
                else
                  raise Riddl::ConnectionError, "#{url.host}:#{url.port}/#{url.path} not reachable - #{e.message}."
                end
              end
            end
            response_headers = {}
            res.each do |k,v|
              if v.nil?
                response_headers[k.name.upcase.gsub(/\-/,'_')] = v
              else  
                response_headers[k.upcase.gsub(/\-/,'_')] = v
              end  
            end
            return res.code.to_i, response, response_headers
            #}}} 
          elsif url.class == URI::Generic && url.scheme.downcase == 'xmpp'
            #{{{
            req = Riddl::Client::XMPPRequest.new(riddl_method,url.user + "@" + url.host,url.path,parameters,headers,qs,ack)
            return req.simulate if simulate

            sig = SignalWait.new
            stanza = req.stanza

            @options[:debug].puts(stanza) if @options[:debug]

            status = 404
            response = []
            response_headers = {}
            if ack
              @options[:xmpp].write_with_handler(stanza) do |raw|
                res = XML::Smart::Dom::Element.new(raw).parent
                @options[:debug].puts(res.to_s) if @options[:debug]
                res.register_namespace 'xr', Riddl::Protocols::XMPP::XR_NS
                if res.find('/message/error').empty?
                  status = 200
                  response_headers = {}
                  res.find('/message/xr:header').each do |e|
                    response_headers[e.attributes['name']] = e.text
                  end
                  response = Protocols::XMPP::Parser.new('', res).params
                else
                  res.register_namespace 'se', Blather::StanzaError::STANZA_ERR_NS
                  err = res.find('string(/message/error/se:text)')
                  status = (err.match(/\d+/)[0] || 209).to_i
                end  
                sig.continue
              end
              sig.wait
            else
              status = 200
              @options[:xmpp].write stanza 

              # xmpp writes in next_tick so we have to fucking wait also a tick
              # to ensure that all shit has been written. fuck. not the best
              # solution, but scripts may preemtively quit if we dont do it. if
              # anybody knows a better solution, please tell me.

              ### UPDATE todo, we produce deadlocks here, rethink this mess
              # EM.next_tick { sig.continue }
              # sig.wait
            end
            return status, response, response_headers
            #}}}
          end
          raise URIError, "not a valid URI (http, https, xmpp are accepted)"
        end #}}}
        private :make_request

      end #}}}

      class HTTPRequest < Net::HTTPGenericRequest #{{{
        def initialize(method, path, parameters, headers, qs)
          path = (path.strip == '' ? '/' : path)
          path += "?#{qs}" unless qs == ''
          super method, true, true, path, headers
          tmp = Protocols::HTTP::Generator.new(parameters,self).generate(:input)
          self.content_length = tmp.size
          self.body_stream = tmp
        end

        def supply_default_content_type
          ### none, Protocols::HTTP::Generator handles this
        end

        def simulate
          sock = StringIO.new('')
          self.exec(sock,"1.1",self.path)
          sock.rewind
          [nil, sock, []]
        end
      end # }}}

      class XMPPRequest #{{{
        attr_reader :stanza

        def initialize(method, to, path, parameters, headers, qs, ack)
          path = (path.strip == '' ? '' : path)
          path += "/?#{qs}" unless qs == ''
          path.gsub!(/\/+/,'/')
          @stanza = Protocols::XMPP::Generator.new(method,parameters,headers,ack).generate
          @stanza.to = to + path
        end

        def simulate
          sock = StringIO.new('')
          sock.write @stanza.to_s
          sock.rewind
          [nil, sock, []]
        end
      end #}}}

    end

  end

end
