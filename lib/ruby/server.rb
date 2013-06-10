require File.expand_path(File.dirname(__FILE__) + '/constants')
require File.expand_path(File.dirname(__FILE__) + '/websocket')
require File.expand_path(File.dirname(__FILE__) + '/implementation')
require File.expand_path(File.dirname(__FILE__) + '/httpparser')
require File.expand_path(File.dirname(__FILE__) + '/httpgenerator')
require File.expand_path(File.dirname(__FILE__) + '/header')
require File.expand_path(File.dirname(__FILE__) + '/parameter')
require File.expand_path(File.dirname(__FILE__) + '/error')
require File.expand_path(File.dirname(__FILE__) + '/wrapper')
require File.expand_path(File.dirname(__FILE__) + '/utils/description')

require 'optparse'
require 'stringio'
require 'rack/content_length'
require 'rack/chunked'
require 'securerandom'
require 'blather/client/dsl'

module Riddl

  class Server

    class Execution #{{{
      attr_reader :response,:headers
      def initialize(response,headers)
        @response = (response.is_a?(Array) ? response : [response])
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

    class XMPP; include Blather::DSL; end

    OPTS = { 
      :host     => 'localhost',
      :port     => 9292,
      :secure   => false,
      :mode     => :debug,
      :basepath => File.expand_path(File.dirname($0)),
      :pidfile  => File.basename($0,'.rb') + '.pid',
      :conffile => File.basename($0,'.rb') + '.conf'
    }

    def loop! #{{{
      ########################################################################################################################
      # parse arguments
      ########################################################################################################################
      verbose = false
      operation = "start"
      ARGV.options { |opt|
        opt.summary_indent = ' ' * 4
        opt.banner = "Usage:\n#{opt.summary_indent}ruby server.rb [options] start|startclean|stop|restart|info\n"
        opt.on("Options:")
        opt.on("--verbose", "-v", "Do not daemonize. Write ouput to console.") { verbose = true }
        opt.on("--help", "-h", "This text.") { puts opt; exit }
        opt.separator(opt.summary_indent + "start|stop|restart|info".ljust(opt.summary_width+1) + "Do operation start, stop, restart or get information.")
        opt.separator(opt.summary_indent + "startclean".ljust(opt.summary_width+1) + "Delete all instances before starting.")
        opt.parse!
      }
      unless %w{start startclean stop restart info}.include?(ARGV[0])
        puts ARGV.options
        exit
      end
      operation = ARGV[0]
      
      ########################################################################################################################
      # status and info
      ########################################################################################################################
      pid = File.read(@riddl_opts[:basepath] + '/' + @riddl_opts[:pidfile]).to_i rescue pid = 666
      status = Proc.new do
        begin
          Process.getpgid pid
          true
        rescue Errno::ESRCH
          false
        end
      end
      if operation == "info" && status.call == false
        puts "Server (#{@riddl_opts[:url]}) not running"
        exit
      end
      if operation == "info" && status.call == true
        puts "Server (#{@riddl_opts[:url]}) running as #{pid}"
        begin
          stats = `ps -o "vsz,rss,lstart,time" -p #{pid}`.split("\n")[1].strip.split(/ +/)
          puts "Virtual:  #{"%0.2f" % (stats[0].to_f/1024)} MiB"
          puts "Resident: #{"%0.2f" % (stats[1].to_f/1024)} MiB"
          puts "Started:  #{stats[2..-2].join(' ')}"
          puts "CPU Time: #{stats.last}"
        rescue
        end
        exit
      end
      if %w{start startclean}.include?(operation) && status.call == true
        puts "Server (#{@riddl_opts[:url]}) already started"
        exit
      end
      
      ########################################################################################################################
      # stop/restart server
      ########################################################################################################################
      if %w{stop restart}.include?(operation)
        if status.call == false
          puts "Server (#{@riddl_opts[:url]}) maybe not started?"
        else
          puts "Server (#{@riddl_opts[:url]}) stopped"
          puts "Waiting while server goes down ..."
          while status.call
            Process.kill "SIGTERM", pid
            sleep 0.3
          end  
        end
        exit unless operation == "restart"
      end
      
      ########################################################################################################################
      # start server
      ########################################################################################################################
      if operation == 'startclean'
        Dir.glob(File.expand_path(@riddl_opts[:basepath] + '/instances/*')).each do |d|
          FileUtils.rm_r(d) if File.basename(d) =~ /^\d+$/
        end
      end

      app = Rack::Builder.new self
      unless @riddl_logger.nil?
        app.use Rack::CommonLogger, @riddl_logger
      end

      server = if verbose
        Rack::Server.new(
          :app => app,
          :Port => @riddl_opts[:port],
          :environment => (@riddl_opts[:mode] == :debug ? 'development' : 'deployment'),
          :server => 'thin',
          :pid => File.expand_path(@riddl_opts[:basepath] + '/' + @riddl_opts[:pidfile])
        )
      else
        server = Rack::Server.new(
          :app => app,
          :Port => @riddl_opts[:port],
          :environment => 'none',
          :server => 'thin',
          :pid => File.expand_path(@riddl_opts[:basepath] + '/' + @riddl_opts[:pidfile]),
          :daemonize => true
        )
      end

      # remove LINT in any case as it breaks websockets
      server.middleware.each do |k,v|
        v.delete [Rack::Lint]
      end  

      EM.run do
        puts "Server (#{@riddl_opts[:url]}) started as #{Process.pid}"
        puts "XMPP support (#{@riddl_xmpp_user}) active" if @riddl_xmpp_user && @riddl_xmpp_pass
        server.start
        if @riddl_xmpp_user && @riddl_xmpp_pass
          xmpp = XMPP.new
          xmpp.setup @riddl_xmpp_user, @riddl_xmpp_pass
          xmpp.message do |m|
            __xmpp_call(m)
          end
          xmpp.run
        end  
      end
    end #}}}

    def initialize(riddl,opts={},&blk)# {{{
      @riddl_opts = {}
      OPTS.each do |k,v|
        @riddl_opts[k] = opts.has_key?(k) ? opts[k] : v
      end

      if File.exists?(@riddl_opts[:basepath] + '/' + @riddl_opts[:conffile])
        eval(File.read(@riddl_opts[:basepath] + '/' + @riddl_opts[:conffile]))
      end
      @riddl_opts[:url] = (@riddl_opts[:secure] ? 'https://' : 'http://') + @riddl_opts[:host] + ':' + @riddl_opts[:port].to_s

      @riddl_logger             = nil
      @riddl_process_out        = true 
      @riddl_cross_site_xhr     = false
      @accessible_description   = false
      @riddl_description_string = ''
      @riddl_paths              = []  

      @riddl_interfaces = {}
      instance_eval(&blk) if block_given?

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

    def call(env)# {{{
      dup.__http_call(env)
    end# }}}

    def __call #{{{
      @riddl_message = @riddl.io_messages(@riddl_matching_path[0],@riddl_method,@riddl_parameters,@riddl_headers)
      if @riddl_message.nil?
        if @riddl_info[:env].has_key?('HTTP_ORIGIN') && @riddl_cross_site_xhr
          @riddl_res['Access-Control-Allow-Origin'] = '*'
          @riddl_res['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
          @riddl_res['Access-Control-Allow-Headers'] = @riddl_info[:env]['HTTP_ACCESS_CONTROL_REQUEST_HEADERS'] if @riddl_info[:env]['HTTP_ACCESS_CONTROL_REQUEST_HEADERS']
          @riddl_res['Access-Control-Max-Age'] = '0'
          @riddl_res['Content-Length'] = '0'
          @riddl_status = 200
        else
          @riddl_log.write "501: the #{@riddl_method} parameters are not matching anything in the description.\n"
          @riddl_status = 501 # not implemented?!
        end  
      else
        if get 'riddl-description-request'
          run Riddl::Utils::Description::XML, @riddl_description_string 
        else
          if @riddl.description?
            instance_exec(@riddl_info, &@riddl_interfaces[nil])  
          elsif @riddl.declaration?
            ifs = @riddl_message.route? ? @riddl_message.route : [@riddl_message]
            ifs.each do |m|
              @riddl_path = '/'
              if m.interface.base.nil?
                if @riddl_interfaces.key? m.interface.name
                  @riddl_info[:r] = m.interface.real_path(@riddl_pinfo).sub(/\//,'').split('/')
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
                run Riddl::Utils::Description::Call, @riddl_exe, @riddl_pinfo, m.interface.top, m.interface.base, m.interface.des.to_doc, m.interface.real_path(@riddl_pinfo)
              end
              break unless @riddl_status == 200
              @riddl_info.merge!(:h => @riddl_exe.headers, :p => @riddl_exe.response)
            end
          end
        end
        if @riddl_info[:env].has_key?('HTTP_ORIGIN') && @riddl_cross_site_xhr
          @riddl_res['Access-Control-Allow-Origin'] = '*'
          @riddl_res['Access-Control-Max-Age'] = '0'
        end
      end  
    end #}}}

    def __xmpp_call(raw) #{{{
      Dir.chdir(@riddl_opts[:basepath]) if @riddl_opts[:basepath]
      @riddl_log = @riddl_logger

      @riddl_env = XML::Smart::Dom::Element.new(raw).parent
      @riddl_env.register_namespace 'o', 'http://www.fp7-adventure.eu/ns/xmpp-rest/operation'
      @riddl_env.register_namespace 'h', 'http://www.fp7-adventure.eu/ns/xmpp-rest/header'
      @riddl_env.register_namespace 'p', 'http://www.fp7-adventure.eu/ns/xmpp-rest/part'
      @riddl_res = {}
      @riddl_status = 404

      @riddl_pinfo = ('/' + @riddl_env.root.attributes['to'].sub(/^[^\/]+/,'')).gsub(/\/+/,'/')
      @riddl_pinfo.gsub!(/\?(.*)/).each do
        @riddl_query_string = $1
        ''
      end
      @riddl_matching_path = @riddl_paths.find{ |e| e[1] =~ @riddl_pinfo }

      if @riddl_matching_path
        @riddl_method = @riddl_env.find('string(/message/o:operation/@type)')

        @riddl_headers = {}
        @riddl_env.find('/message/h:header').each do |e|
          @riddl_headers[e.attributes['name']] = e.text
        end
        @riddl_parameters = []
        @riddl_env.find('/message/p:part').each do |e|
          @riddl_parameters
        end


        @riddl_path = '/'

      end  
    end #}}}

    def __http_call(env) #{{{
      Dir.chdir(@riddl_opts[:basepath]) if @riddl_opts[:basepath]

      @riddl_env = env
      @riddl_env['rack.logger'] =  @riddl_logger if @riddl_logger
      @riddl_log = @riddl_logger || @riddl_env['rack.errors'] 
      @riddl_res = Rack::Response.new
      @riddl_status = 404

      @riddl_pinfo = @riddl_env["PATH_INFO"].gsub(/\/+/,'/')
      @riddl_matching_path = @riddl_paths.find{ |e| e[1] =~ @riddl_pinfo }

      if @riddl_matching_path
        @riddl_query_string = @riddl_env['QUERY_STRING']
        @riddl_raw = @riddl_env['rack.input']

        @riddl_headers = {}
        @riddl_env.each do |h,v|
          @riddl_headers[$1] = v if h =~ /^HTTP_(.*)$/
        end
        @riddl_parameters = HttpParser.new(
          @riddl_query_string,
          @riddl_raw,
          @riddl_env['CONTENT_TYPE'],
          @riddl_env['CONTENT_LENGTH'],
          @riddl_env['HTTP_CONTENT_DISPOSITION'],
          @riddl_env['HTTP_CONTENT_ID'],
          @riddl_env['HTTP_RIDDL_TYPE']
        ).params

        @riddl_method = @riddl_env['REQUEST_METHOD'].downcase
        @riddl_path = '/'
        @riddl_info = { 
          :h => @riddl_headers,
          :p => @riddl_parameters,
          :r => @riddl_pinfo.sub(/\//,'').split('/').map{|e|HttpParser::unescape(e)}, 
          :s => @riddl_matching_path[0].sub(/\//,'').split('/').map{|e|HttpParser::unescape(e)},
          :m => @riddl_method, 
          :env => @riddl_env.reject{|k,v| k =~ /^rack\./},
          :match => []
        }

        if @riddl_info[:env]["HTTP_CONNECTION"] =~ /Upgrade/ && @riddl_info[:env]["HTTP_UPGRADE"] =~ /\AWebSocket\z/i
          # TODO raise error when declaration and route or (not route and non-local interface)
          # raise SpecificationError, 'RIDDL description does not conform to specification' unless @riddl.validate!
          instance_exec(@riddl_info, &@riddl_interfaces[nil])
          return [-1, {}, []]
        else
          __call
          @riddl_res.status = @riddl_status
        end  
      else
        @riddl_log.write "404: this resource for sure does not exist.\n"
        @riddl_res.status = 404 # client requests wrong path
      end
      if @riddl_exe
        if @riddl_res.status == 200
          @riddl_res.write HttpGenerator.new(@riddl_exe.response,@riddl_res).generate.read
        end  
        @riddl_exe.headers.each do |n,h|
          @riddl_res[n] = h
        end
      end
      @riddl_res.finish
    end #}}} 
    
    def process_out(pout)# {{{
      @riddl_process_out = pout
    end# }}}
    def xmpp(user,pass)# {{{
      @riddl_xmpp_user = user
      @riddl_xmpp_pass = pass
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
      if what.class == Class && what.superclass == Riddl::WebSocketImplementation
        data = WebSocketParserData.new
        data.headers = @riddl_headers
        data.request_path = @riddl_pinfo
        data.request_url = @riddl_pinfo + '?' + @riddl_query_string
        data.query_string = @riddl_query_string
        data.http_method = @riddl_method
        data.body = @riddl_raw.read
        w = what.new(@riddl_info.merge!(:a => args, :version => @riddl_info[:env]['HTTP_SEC_WEBSOCKET_VERSION']), :match => matching_path)
        w.io = Riddl::WebSocket.new(w, @riddl_info[:env]['thin.connection'])
        w.io.dispatch(data)

      end  
      if what.class == Class && what.superclass == Riddl::Implementation
        w = what.new(@riddl_info.merge!(:a => args, :match => matching_path))
        @riddl_exe = Riddl::Server::Execution.new(w.response,w.headers)
        @riddl_status = w.status
        if @riddl_process_out && @riddl_status == 200
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
    def post(min='*');   return false if     @riddl_message.nil?; @riddl_path == '/' + @riddl_info[:s].join('/') && min == @riddl_message.in.name && @riddl_method == 'post'   end
    def get(min='*');    return false if     @riddl_message.nil?; @riddl_path == '/' + @riddl_info[:s].join('/') && min == @riddl_message.in.name && @riddl_method == 'get'    end
    def delete(min='*'); return false if     @riddl_message.nil?; @riddl_path == '/' + @riddl_info[:s].join('/') && min == @riddl_message.in.name && @riddl_method == 'delete' end
    def put(min='*');    return false if     @riddl_message.nil?; @riddl_path == '/' + @riddl_info[:s].join('/') && min == @riddl_message.in.name && @riddl_method == 'put'    end
    def websocket;       return false unless @riddl_message.nil?; @riddl_path == '/' + @riddl_info[:s].join('/')                                                               end

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
