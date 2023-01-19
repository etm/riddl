require File.expand_path(File.dirname(__FILE__) + '/constants')
require File.expand_path(File.dirname(__FILE__) + '/implementation')
require File.expand_path(File.dirname(__FILE__) + '/protocols/http/parser')
require File.expand_path(File.dirname(__FILE__) + '/protocols/http/generator')
require File.expand_path(File.dirname(__FILE__) + '/protocols/utils')
require File.expand_path(File.dirname(__FILE__) + '/protocols/websocket')
require File.expand_path(File.dirname(__FILE__) + '/protocols/sse')
require File.expand_path(File.dirname(__FILE__) + '/header')
require File.expand_path(File.dirname(__FILE__) + '/parameter')
require File.expand_path(File.dirname(__FILE__) + '/error')
require File.expand_path(File.dirname(__FILE__) + '/wrapper')
require File.expand_path(File.dirname(__FILE__) + '/utils/description')

require 'optparse'
require 'daemonite'
require 'stringio'
require 'rack/content_length'
require 'rack/chunked'
require 'securerandom'
require 'psych.rb'


module Riddl

  class Server

    class Execution #{{{
      attr_reader :response,:headers
      def initialize(response,headers)
        @response = (response.is_a?(Array) ? response.dup : [response])
        @headers  = (headers.is_a?(Array) ? headers : [headers])
        @response.delete_if do |r|
          r.class != Riddl::Parameter::Simple && r.class != Riddl::Parameter::Complex
        end
        @headers.delete_if do |h|
          h.class != Riddl::Header
        end
        @headers.compact!
        @response.compact!
        @headers = Hash[ @headers.map{ |h| [h.name, h.value] } ]
      end
    end #}}}

    include Daemonism

    attr_reader :riddl_log, :riddl_method, :riddl_pinfo, :riddl_status

    def initialize(riddl,opts={},&blk)# {{{
      @riddl_opts = DAEMONISM_DEFAULT_OPTS.merge({
        :bind         => '0.0.0.0',
        :host         => 'localhost',
        :port         => 9292,
        :secure       => false,
        :verbose      => false,
        :http_only    => false,
        :runtime_opts => [
          ["--port [PORT]", "-p [PORT]", "Specify http port.", ->(p){
            @riddl_opts[:port] = p.to_i
            @riddl_opts[:pidfile] = @riddl_opts[:pidfile].gsub(/\.pid/,'') + '-' + @riddl_opts[:port].to_s + '.pid'
          }],
          ["--http-only", "-s", "Only http, no other protocols.", ->(){ @riddl_opts[:http_only] = true }]
        ],
        :runtime_cmds => [],
        :runtime_proc => Proc.new { |opts|
          @riddl_opts[:cmdl_info] = (@riddl_opts[:secure] ? 'https://' : 'http://') + @riddl_opts[:host] + ':' + @riddl_opts[:port].to_s
          @riddl_opts[:url] ||= @riddl_opts[:cmdl_info]
        }
      }).merge(opts)

      @riddl_logger             = nil
      @riddl_process_out        = true
      @riddl_cross_site_xhr     = false
      @accessible_description   = false
      @riddl_description_string = ''
      @riddl_paths              = []

      @riddl_at_exit            = nil

      @riddl_interfaces         = {}

      daemonism @riddl_opts, &blk

      @riddl = Riddl::Wrapper.new(riddl,@accessible_description)
      if @riddl.description?
        raise SpecificationError, 'RIDDL description does not conform to specification' unless @riddl.validate!
        @riddl_description_string = @riddl.description.xml
      elsif @riddl.declaration?
        raise SpecificationError, 'RIDDL declaration does not conform to specification' unless @riddl.validate!
        @riddl_description_string = @riddl.declaration.description_xml
      else
        raise SpecificationError, 'Not a RIDDL file'
      end

      @riddl.load_necessary_handlers!
      @riddl_paths = @riddl.paths
    end# }}}

    def loop! #{{{
      app = Rack::Builder.new self
      unless @riddl_logger.nil?
        app.use Rack::CommonLogger, @riddl_logger
      end

      server = Rack::Server.new(
        :app => app,
        :Host => @riddl_opts[:bind],
        :Port => @riddl_opts[:port],
        :environment => @riddl_opts[:verbose] ? 'deployment' : 'none',
        :server => 'thin',
        :signals => false
      )
      p @at_startup
      p @opts
      @at_startup.call(@opts) if @at_startup
      if @riddl_opts[:custom_protocol] && !@riddl_opts[:http_only]
        @riddl_opts[:custom_protocol] = @riddl_opts[:custom_protocol].new(@riddl_opts)
        puts @riddl_opts[:custom_protocol].support if @riddl_opts[:custom_protocol].support
      end
      begin
        EM.run do
          if @riddl_opts[:secure]
            server.start do |srv|
              srv.ssl = true
              srv.ssl_options = @riddl_opts[:secure_options]
            end
          else
            server.start
          end

          if @riddl_opts[:custom_protocol] && !@riddl_opts[:http_only]
            @riddl_opts[:custom_protocol].start
          end

          [:INT, :TERM].each do |signal|
            Signal.trap(signal) do
              if @riddl_opts[:cleanup]
                @riddl_opts[:cleanup].call
              end
              EM.stop
            end
          end
          [:HUP].each do |signal|
            Signal.trap(signal) do
              EM.stop
            end
          end

          if @riddl_opts[:parallel]
            EM.defer do
              @riddl_opts[:parallel].call
            end
          end
        end
      rescue => e
        if @riddl_opts[:custom_protocol] && !@riddl_opts[:http_only]
          @riddl_opts[:custom_protocol].error_handling(e)
        end
        puts "Server (#{@riddl_opts[:cmdl_info]}) stopped due to connection error (PID:#{Process.pid})"
      end
    end #}}}

    def parallel(&blk)
      @riddl_opts[:parallel] = blk
    end
    def cleanup(&blk)
      @riddl_opts[:cleanup] = blk
    end

    def call(env)# {{{
      dup.__http_call(env)
    end# }}}

    def __call #{{{
      @riddl_message = @riddl.io_messages(@riddl_matching_path[0],@riddl_method,@riddl_parameters,@riddl_headers)
      if @riddl_message.nil?
        if @riddl_info[:env].has_key?('HTTP_ORIGIN') && @riddl_cross_site_xhr && @riddl_method == 'options'
          @riddl_res['Access-Control-Allow-Origin'] = '*'
          @riddl_res['Access-Control-Allow-Methods'] = 'GET, POST, PUT, PATCH, DELETE, OPTIONS'
          @riddl_res['Access-Control-Allow-Headers'] = @riddl_info[:env]['HTTP_ACCESS_CONTROL_REQUEST_HEADERS'] if @riddl_info[:env]['HTTP_ACCESS_CONTROL_REQUEST_HEADERS']
          @riddl_res['Access-Control-Max-Age'] = '0'
          @riddl_res['Content-Length'] = '0'
          @riddl_status = 200
        else
          @riddl_log.write "501: a #{@riddl_method} with the these parameters is not part in the description (xml).\n"
          @riddl_status = 501 # not implemented?!
        end
      else
        if !@riddl_message.nil? && @accessible_description && @riddl_message.in.name == 'riddl-description-request' && @riddl_method == 'get' &&  '/' + @riddl_info[:s].join('/') == '/'
          run Riddl::Utils::Description::RDR, @riddl_description_string
        elsif !@riddl_message.nil? && @accessible_description && @riddl_message.in.name == 'riddl-resource-description-request' && @riddl_method == 'get'
          @riddl_path = File.dirname('/' + @riddl_info[:s].join('/')).gsub(/\/+/,'/')
          on resource File.basename('/' + @riddl_info[:s].join('/')).gsub(/\/+/,'/') do
            run Riddl::Utils::Description::RDR, @riddl.resource_description(@riddl_matching_path[0])
          end
        else
          if @riddl.description?
            instance_exec(@riddl_info, &@riddl_interfaces[nil])
          elsif @riddl.declaration?
            mess = @riddl_message
            @riddl_message.route_to_a.each do |m|
              @riddl_message = m
              @riddl_path = '/'
              if m.interface.base.nil?
                if @riddl_interfaces.key? m.interface.name
                  @riddl_info[:r] = m.interface.real_path(@riddl_pinfo).sub(/^\//,'').split('/')
                  @riddl_info[:h]['RIDDL_DECLARATION_PATH'] = @riddl_pinfo
                  @riddl_info[:h]['RIDDL_DECLARATION_RESOURCE'] = m.interface.top
                  @riddl_info[:s] = m.interface.sub.sub(/\//,'').split('/')
                  @riddl_info.merge!(:match => matching_path)
                  instance_exec(@riddl_info, &@riddl_interfaces[m.interface.name])
                else
                  @riddl_log.write "501: not implemented (for remote: add @location in declaration; for local: add to Riddl::Server).\n"
                  @riddl_status = 501 # not implemented?!
                  break
                end
              else
                run Riddl::Utils::Description::Call, @riddl_exe, @riddl_pinfo, m.interface.top, m.interface.base, m.interface.real_path(@riddl_pinfo)
              end
              break if @riddl_status < 200 || @riddl_status >= 300
              @riddl_info.merge!(:h => @riddl_exe.headers, :p => @riddl_exe.response)
            end
            @riddl_message = mess
          end
        end
        if @riddl_info[:env].has_key?('HTTP_ORIGIN') && @riddl_cross_site_xhr
          @riddl_res['Access-Control-Allow-Origin'] = '*'
          @riddl_res['Access-Control-Max-Age'] = '0'
        end
      end
    end #}}}

    def __http_call(env) #{{{
      @riddl_env = env
      @riddl_env['rack.logger'] =  @riddl_logger if @riddl_logger
      @riddl_log = @riddl_logger || @riddl_env['rack.errors']
      @riddl_res = Rack::Response.new
      @riddl_status = 404

      @riddl_pinfo = Riddl::Protocols::Utils::unescape(@riddl_env["PATH_INFO"].gsub(/\/+/,'/'))
      @riddl_matching_path = @riddl_paths.find{ |e| @riddl_pinfo.match(e[1]).to_s.length == @riddl_pinfo.length }

      if @riddl_matching_path
        @riddl_query_string = @riddl_env['QUERY_STRING']
        @riddl_raw = @riddl_env['rack.input']

        @riddl_headers = {}
        @riddl_env.each do |h,v|
          @riddl_headers[$1] = v if h =~ /^HTTP_(.*)$/
        end
        @riddl_parameters = Protocols::HTTP::Parser.new(
          @riddl_query_string,
          @riddl_raw,
          @riddl_env['CONTENT_TYPE'],
          @riddl_env['CONTENT_LENGTH'],
          @riddl_env['HTTP_CONTENT_DISPOSITION'],
          @riddl_env['HTTP_CONTENT_ID'],
          @riddl_env['HTTP_RIDDL_TYPE']
        ).params
        if @riddl_opts[:http_debug]
          pp @riddl_parameters
        end

        @riddl_method = @riddl_env['REQUEST_METHOD'].downcase
        @riddl_path = '/'
        @riddl_info = {
          :h => @riddl_headers,
          :p => @riddl_parameters,
          :r => @riddl_pinfo.sub(/^\//,'').split('/').map{|e|Protocols::Utils::unescape(e)},
          :s => @riddl_matching_path[0].sub(/\//,'').split('/'),
          :m => @riddl_method,
          :env => @riddl_env.reject{|k,v| k =~ /^rack\./}.merge({'riddl.transport' => 'http', 'custom_protocol' => @riddl_opts[:custom_protocol]}),
          :match => []
        }

        if @riddl_info[:env]['HTTP_CONNECTION'] =~ /Upgrade/ && @riddl_info[:env]['HTTP_UPGRADE'] =~ /\AWebSocket\z/i
          # TODO raise error when declaration and route or (not route and non-local interface)
          # raise SpecificationError, 'RIDDL description does not conform to specification' unless @riddl.validate!
          @riddl_info[:m] = @riddl_method = 'websocket'
          @riddl_message = @riddl.io_messages(@riddl_matching_path[0],'websocket',@riddl_parameters,@riddl_headers)
          if @riddl.description?
            instance_exec(@riddl_info, &@riddl_interfaces[nil])
          elsif @riddl.declaration?
            # one ws connection, no overlay
            unless @riddl_message.nil?
              if @riddl_interfaces.key? @riddl_message.interface.name
                @riddl_info[:r] = @riddl_message.interface.real_path(@riddl_pinfo).sub(/^\//,'').split('/')
                @riddl_info[:h]['RIDDL_DECLARATION_PATH'] = @riddl_pinfo
                @riddl_info[:h]['RIDDL_DECLARATION_RESOURCE'] = @riddl_message.interface.top
                @riddl_info[:s] = @riddl_message.interface.sub.sub(/\//,'').split('/')
                @riddl_info.merge!(:match => matching_path)
                instance_exec(@riddl_info, &@riddl_interfaces[@riddl_message.interface.name])
              end
            end
          end
          throw :async
        elsif @riddl_info[:env]['HTTP_ACCEPT'] == 'text/event-stream'
          @riddl_info[:m] = @riddl_method = 'sse'
          @riddl_message = @riddl.io_messages(@riddl_matching_path[0],'sse',@riddl_parameters,@riddl_headers)
          if @riddl.description?
            instance_exec(@riddl_info, &@riddl_interfaces[nil])
          elsif @riddl.declaration?
            # one ws connection, no overlay
            unless @riddl_message.nil?
              if @riddl_interfaces.key? @riddl_message.interface.name
                @riddl_info[:r] = @riddl_message.interface.real_path(@riddl_pinfo).sub(/^\//,'').split('/')
                @riddl_info[:h]['RIDDL_DECLARATION_PATH'] = @riddl_pinfo
                @riddl_info[:h]['RIDDL_DECLARATION_RESOURCE'] = @riddl_message.interface.top
                @riddl_info[:s] = @riddl_message.interface.sub.sub(/\//,'').split('/')
                @riddl_info.merge!(:match => matching_path)
                instance_exec(@riddl_info, &@riddl_interfaces[@riddl_message.interface.name])
              end
            end
          end
          throw :async
        else
          __call
        end
      else
        @riddl_log.write "404: this resource for sure does not exist.\n"
        @riddl_status = 404 # client requests wrong path
      end
      if @riddl_exe
        @riddl_res.write Protocols::HTTP::Generator.new(@riddl_exe.response,@riddl_res).generate.read
        @riddl_exe.headers.each do |n,h|
          @riddl_res[n] = h
        end
      end
      @riddl_res.status = @riddl_status
      @riddl_res.finish
    end #}}}

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
    def interface(name,&block) #{{{
      @riddl_interfaces[name] = block
    end #}}}

    def on(resource, &block)# {{{
      if @riddl_paths.empty? # default interface, when a description and "on" syntax in server
        @riddl_interfaces[nil] = block
        return
      end

      @riddl_path << (@riddl_path == '/' ? resource : '/' + resource)

      ### only descend when there is a possibility that it holds the right path
      rp = @riddl_path.sub(/\//,'').split('/')

      block.call(@riddl_info.merge!(:match => matching_path)) if @riddl_info[:s][rp.length-1] == rp.last
      @riddl_path = File.dirname(@riddl_path).gsub(/\/+/,'/')
    end# }}}

    def use(blk,*args)# {{{
      instance_eval(&blk)
    end# }}}

    def run(what,*args)# {{{
      return if @riddl_path == ''
      if what.class == Class && what.superclass == Riddl::SSEImplementation
        data = Riddl::Protocols::SSE::ParserData.new
        data.request_path = @riddl_pinfo
        data.request_url = @riddl_pinfo + '?' + @riddl_query_string
        data.query_string = @riddl_query_string
        data.http_method = @riddl_env['REQUEST_METHOD']
        data.body = @riddl_env['rack.input'].read
        data.headers = Hash[
          @riddl_headers.map { |key, value|  [key.downcase.gsub('_','-'), value] }
        ]
        w = what.new(@riddl_info.merge!(:a => args, :match => matching_path))
        w.io = Riddl::Protocols::SSE.new(w, @riddl_env)
        w.io.dispatch(data, @riddl_cross_site_xhr)
      end
      if what.class == Class && what.superclass == Riddl::WebSocketImplementation
        data = Riddl::Protocols::WebSocket::ParserData.new
        data.request_path = @riddl_pinfo
        data.request_url = @riddl_pinfo + '?' + @riddl_query_string
        data.query_string = @riddl_query_string
        data.http_method = @riddl_env['REQUEST_METHOD']
        data.body = @riddl_env['rack.input'].read
        data.headers = Hash[
          @riddl_headers.map { |key, value|  [key.downcase.gsub('_','-'), value] }
        ]
        w = what.new(@riddl_info.merge!(:a => args, :version => @riddl_env['HTTP_SEC_WEBSOCKET_VERSION'], :match => matching_path))
        w.io = Riddl::Protocols::WebSocket.new(w, @riddl_env['thin.connection'])
        w.io.dispatch(data)
      end
      if what.class == Class && what.superclass == Riddl::Implementation
        w = what.new(@riddl_info.merge!(:a => args, :match => matching_path))
        @riddl_exe = Riddl::Server::Execution.new(w.response,w.headers)
        @riddl_status = w.status
        if @riddl_process_out && @riddl_status >= 200 && @riddl_status < 300
          unless @riddl.check_message(@riddl_exe.response,@riddl_exe.headers,@riddl_message.out)
            @riddl_log.write "500: the return for the #{@riddl_method} is not matching anything in the description.\n"
            @riddl_status = 500
            return
          end
        end
      end
    end# }}}

    def method(what)# {{{
      if !@riddl_message.nil? && what.class == Hash && what.length == 1
        met, min = what.first
        @riddl_path == @riddl_matching_path[0] && min == @riddl_message.in.name && @riddl_method == met.to_s.downcase
      else
        false
      end
    end  # }}}
    def post(min='*');   return false if @riddl_message.nil?; @riddl_path == '/' + @riddl_info[:s].join('/') && @riddl_message.in && min == @riddl_message.in.name && @riddl_method == 'post'      end
    def get(min='*');    return false if @riddl_message.nil?; @riddl_path == '/' + @riddl_info[:s].join('/') && @riddl_message.in && min == @riddl_message.in.name && @riddl_method == 'get'       end
    def delete(min='*'); return false if @riddl_message.nil?; @riddl_path == '/' + @riddl_info[:s].join('/') && @riddl_message.in && min == @riddl_message.in.name && @riddl_method == 'delete'    end
    def put(min='*');    return false if @riddl_message.nil?; @riddl_path == '/' + @riddl_info[:s].join('/') && @riddl_message.in && min == @riddl_message.in.name && @riddl_method == 'put'       end
    def patch(min='*');  return false if @riddl_message.nil?; @riddl_path == '/' + @riddl_info[:s].join('/') && @riddl_message.in && min == @riddl_message.in.name && @riddl_method == 'patch'     end
    def websocket;       return false if @riddl_message.nil?; @riddl_path == '/' + @riddl_info[:s].join('/')                                                       && @riddl_method == 'websocket' end
    def sse;             return false if @riddl_message.nil?; @riddl_path == '/' + @riddl_info[:s].join('/')                                                       && @riddl_method == 'sse'       end
    def resource(rname=nil); return rname.nil? ? '{}' : rname end

    def matching_path #{{{
      @riddl_path.sub(/\//,'').split('/')
    end #}}}

    def declaration_path #{{{
      @riddl_info[:h]['RIDDL_DECLARATION_PATH']
    end #}}}
    def declaration_resource #{{{
      @riddl_info[:h]['RIDDL_DECLARATION_RESOURCE']
    end #}}}

  end
end
