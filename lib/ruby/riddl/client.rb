require File.expand_path(File.dirname(__FILE__) + '/wrapper')
require File.expand_path(File.dirname(__FILE__) + '/error')
require File.expand_path(File.dirname(__FILE__) + '/protocols/http/generator')
require File.expand_path(File.dirname(__FILE__) + '/protocols/http/parser')
require File.expand_path(File.dirname(__FILE__) + '/protocols/utils')
require File.expand_path(File.dirname(__FILE__) + '/header')
require File.expand_path(File.dirname(__FILE__) + '/option')

require 'typhoeus'
require 'eventmachine'
require 'em-websocket-client'
require 'uri'
require 'openssl'
require 'digest/md5'

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
      (?:(?:https?|[a-z]{4})://)

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
        if @options[:custom_protocol]
          @options[:custom_protocol] = @options[:custom_protocol].new(@base,@options)
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
          (URI.parse(@base)&.query || '').split(/[#{D}] */n).each do |p|
            k, v = Riddl::Protocols::Utils::unescape(p).split('=', 2)
            parameters << Parameter::Simple.new(k,v,:query)
          end
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

          response = nil
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
            return Riddl::Client::HTTPRequest.new(riddl_method,url.path,parameters,headers,qs).simulate if simulate

            path = (url.path.strip == '' ? '/' : url.path)
            path += "?#{qs}" unless qs == ''
            uri = url.scheme + '://' + url.host + ':' + url.port.to_s + path

            tmp = Protocols::HTTP::Generator.new(parameters,headers).generate(:input)

            opts = {
              :method         => riddl_method,
              :headers        => headers,
              :body           => tmp.read,
              :ssl_verifypeer => false
            }
            if url.user && url.password
              opts[:username] = url.user
              opts[:password] = url.password
              opts[:httpauth] = :auto
            end
            if @options[:debug]
              opts[:verbose] = true ### sadly only to console, does not respect @options[:debug]
            end

            req = Typhoeus::Request.new(uri,opts)
            res = req.run

            bs = Parameter::Tempfile.new("RiddlBody")
            bs.write res.body
            bs.rewind

            response_headers = {}
            res.headers.each do |k,v|
              if v.nil?
                response_headers[k.name.upcase.gsub(/\-/,'_')] = v
              else
                response_headers[k.upcase.gsub(/\-/,'_')] = v
              end
            end

            response = Riddl::Protocols::HTTP::Parser.new(
              "",
              bs,
              response_headers['CONTENT_TYPE'],
              response_headers['CONTENT_LENGTH'].to_i != bs.length ? 0 : response_headers['CONTENT_LENGTH'], # because when gzip content length differs from bs length
              response_headers['CONTENT_DISPOSITION'],
              response_headers['CONTENT_ID'],
              response_headers['RIDDL_TYPE']
            ).params

            return res.code.to_i, response, response_headers
            #}}}
          else
            if @options[:custom_protocol]
              return @options[:custom_protocol].handle(url,riddl_method,parameters,headers,qs,simulate,ack)
            end
          end
          raise URIError, "not a valid URI (http, https, ... are accepted)"
        end #}}}
        private :make_request

      end #}}}

      class HTTPRequest #{{{
        def initialize(method, path, parameters, headers, qs)
          path = (path.strip == '' ? '/' : path)
          path += "?#{qs}" unless qs == ''
          super method, true, true, path, headers
          tmp = Protocols::HTTP::Generator.new(parameters,self).generate(:input)
          self.content_length = tmp.size
          self.body_stream = tmp
        end

        def simulate
          sock = StringIO.new('')
          sock.define_singleton_method(:io) do
            sock
          end
          self.exec(sock,"1.1",self.path)
          sock.rewind
          [nil, sock, []]
        end
      end # }}}

    end

  end

end
