require File.expand_path(File.dirname(__FILE__) + '/constants')
require File.expand_path(File.dirname(__FILE__) + '/websocket')
require File.expand_path(File.dirname(__FILE__) + '/implementation')
require File.expand_path(File.dirname(__FILE__) + '/httpparser')
require File.expand_path(File.dirname(__FILE__) + '/httpgenerator')
require File.expand_path(File.dirname(__FILE__) + '/header')
require File.expand_path(File.dirname(__FILE__) + '/parameter')
require File.expand_path(File.dirname(__FILE__) + '/error')
require File.expand_path(File.dirname(__FILE__) + '/wrapper')

require 'rack'
require 'mongrel'
require 'stringio'
require 'rack/content_length'
require 'rack/chunked'

module Rack #{{{
  module Handler
    class Mongrel < ::Mongrel::HttpHandler
      def process(request, response)
        env = {}.replace(request.params)
        env.delete "HTTP_CONTENT_TYPE"
        env.delete "HTTP_CONTENT_LENGTH"

        env["SCRIPT_NAME"] = ""  if env["SCRIPT_NAME"] == "/"

        rack_input = request.body || StringIO.new('')
        rack_input.set_encoding(Encoding::BINARY) if rack_input.respond_to?(:set_encoding)

        env.update({"rack.version" => Rack::VERSION,
                    "rack.input" => rack_input,
                    "rack.errors" => $stderr,
                    "rack.io" => response.socket,

                    "rack.multithread" => true,
                    "rack.multiprocess" => false, # ???
                    "rack.run_once" => false,

                    "rack.url_scheme" => ["yes", "on", "1"].include?(env["HTTPS"]) ? "https" : "http"
                   })
        env["QUERY_STRING"] ||= ""

        status, headers, body = @app.call(env)

        begin
          response.status = status.to_i
          response.send_status(nil)

          headers.each { |k, vs|
            vs.split("\n").each { |v|
              response.header[k] = v
            }
          }
          response.send_header

          body.each { |part|
            response.write part
            response.socket.flush
          }
        ensure
          body.close  if body.respond_to? :close
        end
      end
    end
  end
end #}}}

module Riddl

  module Utils
    module Description

      class XML < Riddl::Implementation
        def response
          return Riddl::Parameter::Complex.new("riddl-description","text/xml",@a[0])
        end
      end
      
    end
  end

  class Server
    def initialize(riddl,&blk)# {{{
      @riddl_norun = true
      @riddl_logger = nil
      @riddl_process_out = true 
      @riddl_cross_site_xhr = false
      @accessible_description = false
      @riddl_blk =  nil
      instance_eval(&blk)
      @riddl_norun = false

      riddl = Riddl::Wrapper.new(riddl,@accessible_description)
      if riddl.description?
        @riddl_description = riddl
        @riddl_description_string = riddl.description.xml
        raise SpecificationError, 'RIDDL description does not conform to specification' unless @riddl_description.validate!
      elsif riddl.declaration?
        @riddl_declaration = riddl
        raise SpecificationError, 'RIDDL declaration does not conform to specification' unless @riddl_declaration.validate!
        @riddl_description_string = riddl.declaration.description_xml
        @riddl_description = Riddl::Wrapper.new(@riddl_description_string,@accessible_description)
      else
        raise SpecificationError, 'Not a RIDDL file'
      end

      @riddl_description.load_necessary_handlers!
      @riddl_paths = @riddl_description.paths
    end# }}}

    def call(env)# {{{
      dup._call(env)
    end# }}}

    def _call(env)
      time = Time.now  unless @riddl_logger.nil?
      @riddl_pinfo = env["PATH_INFO"].gsub(/\/+/,'/')
      @riddl_env = env
      @riddl_req = Rack::Request.new(env)
      @riddl_res = Rack::Response.new

      @riddl_log = @riddl_env['rack.errors']
      @riddl_matching_path = @riddl_paths.find{ |e| e[1] =~ @riddl_pinfo }

      if @riddl_matching_path
        @riddl_matching_path_pieces = @riddl_matching_path[0].split('/')
        @riddl_headers = {}
        @riddl_env.each do |h,v|
          @riddl_headers[$1] = v if h =~ /^HTTP_(.*)$/
        end
        @riddl_parameters = Riddl::HttpParser.new(
          @riddl_env['QUERY_STRING'],
          @riddl_env['rack.input'],
          @riddl_env['CONTENT_TYPE'],
          @riddl_env['CONTENT_LENGTH'],
          @riddl_env['HTTP_CONTENT_DISPOSITION'],
          @riddl_env['HTTP_CONTENT_ID'],
          @riddl_env['HTTP_RIDDL_TYPE']
        ).params
        @riddl_method = @riddl_env['REQUEST_METHOD'].downcase

        if @riddl_env["HTTP_CONNECTION"] =~ /Upgrade/ && @riddl_env["HTTP_UPGRADE"] =~ /\AWebSocket\z/i
          @riddl_env["HTTP_SEC_WEBSOCKET_VERSION"] = Riddl::WebSocket.handshake @riddl_env
          @riddl_path = '/'
          @riddl_res.status = 404
          instance_exec(info, &@riddl_blk)  
        else
          @riddl_message = @riddl_description.io_messages(@riddl_matching_path[0],@riddl_method,@riddl_parameters,@riddl_headers)
          if @riddl_message.nil?
            if @riddl_env.has_key?('HTTP_ORIGIN') && @riddl_cross_site_xhr
              @riddl_res['Access-Control-Allow-Origin'] = '*'
              @riddl_res['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
              @riddl_res['Access-Control-Allow-Headers'] = @riddl_env['HTTP_ACCESS_CONTROL_REQUEST_HEADERS'] if @riddl_env['HTTP_ACCESS_CONTROL_REQUEST_HEADERS']
              @riddl_res['Access-Control-Max-Age'] = '0'
              @riddl_res['Content-Length'] = '0'
              @riddl_res.status = 200
            else
              @riddl_log.puts "501: the #{@riddl_method} parameters are not matching anything in the description."
              @riddl_res.status = 501 # not implemented?!
            end  
          else
            @riddl_path = '/'
            @riddl_res.status = 404
            run Riddl::Utils::Description::XML, @riddl_description_string if get 'riddl-description-request'
            instance_exec(info, &@riddl_blk)  
            if @riddl_cross_site_xhr
              @riddl_res['Access-Control-Allow-Origin'] = '*'
              @riddl_res['Access-Control-Max-Age'] = '0'
            end
          end  
        end
      else
        @riddl_log.puts "404: this resource for sure does not exist."
        @riddl_res.status = 404 # client requests wrong path
      end
      @riddl_logger.info(@riddl_env,@riddl_res,time) unless @riddl_logger.nil?
      @riddl_res.finish
    end
  
    def on(resource, &block)# {{{
      if @riddl_norun
        @riddl_blk = block if @riddl_blk.nil?
      else
        @riddl_path << (@riddl_path == '/' ? resource : '/' + resource)

        ### only descend when there is a possibility that it holds the right path
        rp = @riddl_path.split('/')
        block.call(info) if @riddl_matching_path_pieces[rp.length-1] == rp.last
        @riddl_path = File.dirname(@riddl_path).gsub(/\/+/,'/')
      end  
    end# }}}
    
    def use(blk,*args)# {{{
      instance_eval(&blk)
    end# }}}

    def process_out(pout)# {{{
      @riddl_process_out = pout
    end# }}}
    def cross_site_xhr(csxhr)# {{{
      @riddl_cross_site_xhr = csxhr
    end# }}}
    def logger(lgr)# {{{
      @riddl_logger = lgr
    end# }}}
    def accessible_description(ad)# {{{
      @accessible_description = ad
    end# }}}

    def run(what,*args)# {{{
      return if @riddl_norun
      return if @riddl_path == ''
      if what.class == Class && what.superclass == Riddl::WebSocketImplementation
        w = what.new(info(:a => args, :io => @riddl_env['rack.io'], :version => @riddl_env['HTTP_SEC_WEBSOCKET_VERSION']))
        w.onopen
        while data = Riddl::WebSocket::read(@riddl_env['rack.io'], @riddl_env['HTTP_SEC_WEBSOCKET_VERSION'])
          w.onmessage(data)
        end  
        w.onclose
      end  
      if what.class == Class && what.superclass == Riddl::Implementation
        w = what.new(info(:a => args))
        response          = w.response
        headers           = w.headers
        @riddl_res.status = w.status

        response = (response.class == Array ? response : [response])
        headers  = (headers.class == Array ? headers : [headers])
        response.delete_if do |r|
          r.class != Riddl::Parameter::Simple && r.class != Riddl::Parameter::Complex
        end
        response.compact!
        if @riddl_process_out && @riddl_res.status == 200
          unless @riddl_description.check_message(response,headers,@riddl_message.out)
            @riddl_log.puts "500: the return for the #{@riddl_method} is not matching anything in the description."
            @riddl_res.status = 500
            return
          end  
        end
        if @riddl_res.status == 200
          @riddl_res.write HttpGenerator.new(response,@riddl_res).generate.read
        end  
        headers.each do |h|
          if h.class == Riddl::Header
            @riddl_res[h.name] = h.value
          end  
        end
      end
    end# }}}

    def method(what)# {{{
      return if @riddl_norun
      if what.class == Hash
        what.each do |met,min|
          return true if check(min) && @riddl_method == met.to_s.downcase
        end  
      end
      false
    end  # }}}
    def post(min='*');   return if @riddl_norun; check(min) && @riddl_method == 'post' end
    def get(min='*');    return if @riddl_norun; check(min) && @riddl_method == 'get' end
    def delete(min='*'); return if @riddl_norun; check(min) && @riddl_method == 'delete' end
    def put(min='*');    return if @riddl_norun; check(min) && @riddl_method == 'put' end
    def websocket;       return if @riddl_norun; return false unless @riddl_message.nil?; @riddl_path == @riddl_matching_path[0] end

    def check(min)#  {{{
      return false if @riddl_message.nil? # for websockets no @riddl_message is set
      @riddl_path == @riddl_matching_path[0] && min == @riddl_message.in.name
    end# }}}

    def resource(path=nil); return if @riddl_norun; path.nil? ? '{}' : path end

    def info(other={})# {{{
      { :h => @riddl_headers, 
        :p => @riddl_parameters, 
        :r => @riddl_pinfo.sub(/\//,'').split('/').map{|e|HttpParser::unescape(e)}, 
        :m => @riddl_method, 
        :env => @riddl_env.reject{|k,v| k =~ /^rack\./}, 
        :match => @riddl_path.sub(/\//,'').split('/') 
      }.merge(other)
    end# }}}

    def description_string# {{{
      @riddl_description_string
    end# }}}

    def facade# {{{
      @riddl_declaration
    end# }}}
  end
end
