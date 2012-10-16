require 'rubygems'
require 'net/https'
require 'socket'
require 'eventmachine'
require 'em-websocket-client'
require 'uri'
require 'openssl'
require 'digest/md5'
require File.expand_path(File.dirname(__FILE__) + '/wrapper')
require File.expand_path(File.dirname(__FILE__) + '/error')
require File.expand_path(File.dirname(__FILE__) + '/httpgenerator')
require File.expand_path(File.dirname(__FILE__) + '/httpparser')
require File.expand_path(File.dirname(__FILE__) + '/header')
require File.expand_path(File.dirname(__FILE__) + '/option')

unless Module.constants.include?('CLIENT_INCLUDED')
  CLIENT_INCLUDED = true

  module Riddl

    class Client
      #{{{
      def initialize(base, riddl=nil, options={})
        @base = base.nil? ? '' : base.gsub(/\/+$/,'')
        @options = options
        @wrapper = nil
        unless riddl.nil?
          @wrapper = (riddl.class == Riddl::Wrapper ? riddl : Riddl::Wrapper::new(riddl))
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
      def get(parameters = []);             resource('/').get(parameters);             end
      def simulate_get(parameters = []);    resource('/').simulate_get(parameters);    end
      def post(parameters = []);            resource('/').post(parameters);            end
      def simulate_post(parameters = []);   resource('/').simulate_post(parameters);   end
      def put(parameters = []);             resource('/').put(parameters);             end
      def simulate_put(parameters = []);    resource('/').simulate_put(parameters);    end
      def delete(parameters = []);          resource('/').delete(parameters);          end
      def simulate_delete(parameters = []); resource('/').simulate_delete(parameters); end
      def request(what)                     resource('/').request(what);               end
      def simulate_request(what)            resource('/').simulate_request(what);      end
      def ws(blk)                           resource('/').ws(blk);                     end
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
                STDERR.puts "WS ERROR: #{e}"
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
        def extract_response_headers(headers) #{{{
          ret = {}
          headers.each do |k,v|
            if v.nil?
              ret[k.name.upcase.gsub(/\-/,'_')] = v
            else  
              ret[k.upcase.gsub(/\-/,'_')] = v
            end  
          end
          ret
        end #}}}
        private :extract_response_headers
        
        def extract_qparams(parameters,method) #{{{
          qparams = []
          starting = true
          parameters.delete_if do |p|
            if starting && p.class == Riddl::Parameter::Simple && method == 'get'
               p.type = :query
            end
            if p.class == Riddl::Parameter::Simple && p.type == :query
              qparams << HttpGenerator::escape(p.name) + (p.value.nil? ? '' : '=' + HttpGenerator::escape(p.value))
              true
            else
              starting = false
              false
            end
          end
          qparams
        end #}}}
        private :extract_qparams

        def merge_paths(int,real) #{{{
          t = int.top.sub(/^\/*/,'').split('/')
          real = real.sub(/^\/*/,'').split('/')
          real = real[t.length..-1]
          base = int.base == '' ? @base : int.base
          base + '/' + real.join('/')
        end #}}}
        private :merge_paths

        def exec_request(riddl_method,parameters,simulate) #{{{
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
          if @wrapper.nil? || @wrapper.description?
            res, response = make_request(@base + @rpath,riddl_method,parameters,headers,qparams,simulate)
            return response if simulate
            if !@wrapper.nil? && res.code.to_i == 200
              unless @wrapper.check_message(response,res,riddl_message.out)
                raise OutputError, "Not a valid output from service."
              end
            end
          elsif !@wrapper.nil? && @wrapper.declaration?
            headers['Riddl-Declaration-Path'] = @rpath
            if riddl_message.route.nil?
              reqp = merge_paths(riddl_message.interface,@rpath)
              res, response = make_request(reqp,riddl_method,parameters,headers,qparams,simulate)
              return response if simulate
              if res.code.to_i == 200
                unless @wrapper.check_message(response,res,riddl_message.out)
                  raise OutputError, "Not a valid output from service."
                end
              end  
            else
              tp = parameters
              th = headers
              tq = qparams
              riddl_message.route.each do |m|
                reqp = merge_paths(m.interface,@rpath)
                res, response = make_request(reqp,riddl_method,tp,th,tq,simulate)
                return response if simulate
                if res.code.to_i != 200 || !@wrapper.check_message(response,res,m.out)
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
          resc = res.code.to_i
          resh = extract_response_headers(res)
          unless role.nil?
            if Riddl::Roles::roles[role]
              response = Riddl::Roles::roles[role]::after(@base + @rpath,riddl_method.downcase,resc,response,resh,options) if Riddl::Roles::roles[role].respond_to?(:after)
            end  
          end  
          return resc, response, resh
        end #}}}
        private :exec_request
        def make_request(url,riddl_method,parameters,headers,qparams,simulate) #{{{
          url = URI.parse(url)
          qs = qparams.join('&')
          req = Riddl::Client::Request.new(riddl_method,url.path,parameters,headers,qs)
          return req.simulate if simulate

          res = response = nil

          http = Net::HTTP.new(url.host, url.port)
          if url.class == URI::HTTPS
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          end  
          deb = nil
          if @options[:debug]
            http.set_debug_output STDOUT
          end  
          http.start do
            http.request(req) do |resp|
              res = resp
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
        end #}}}
        private :make_request
        
      end #}}}

      class Request < Net::HTTPGenericRequest #{{{
        def initialize(method, path, parameters, headers, qs)
          path = (path.strip == '' ? '/' : path)
          path += "?#{qs}" unless qs == ''
          super method, true, true, path, headers
          tmp = HttpGenerator.new(parameters,self).generate(:input)
          self.content_length = tmp.size
          self.body_stream = tmp
        end

        def supply_default_content_type
          ### none, HttpGenerator handles this
        end

        def simulate
          sock = StringIO.new('')
          self.exec(sock,"1.1",self.path)
          sock.rewind
          [nil, sock]
        end
      end #}}}
    end

  end

end
