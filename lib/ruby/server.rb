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

module Riddl

  class Server
    OPTS = { 
      :host     => 'http://localhost',
      :port     => 9292,
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
      pid = File.read(@riddl_opts[:pidfile]) rescue pid = 666
      status = `ps -u #{Process.uid} | grep "#{pid} "`
      if operation == "info" && status.empty?
        puts "Server (#{@riddl_opts[:url]}) not running"
        exit
      end
      if operation == "info" && !status.empty?
        puts "Server (#{@riddl_opts[:url]}) running as #{pid}"
        stats = `ps -o "vsz,rss,lstart,time" -p #{pid}`.split("\n")[1].strip.split(/ +/)
        puts "Virtual:  #{"%0.2f" % (stats[0].to_f/1024)} MiB"
        puts "Resident: #{"%0.2f" % (stats[1].to_f/1024)} MiB"
        puts "Started:  #{stats[2..-2].join(' ')}"
        puts "CPU Time: #{stats.last}"
        exit
      end
      if %w{start startclean}.include?(operation) && !status.empty?
        puts "Server (#{@riddl_opts[:url]}) already started"
        exit
      end
      
      ########################################################################################################################
      # stop/restart server
      ########################################################################################################################
      if %w{stop restart}.include?(operation)
        if status.empty?
          puts "Server (#{@riddl_opts[:url]}) maybe not started?"
        else
          puts "Server (#{@riddl_opts[:url]}) stopped"
          puts "Waiting while server goes down ..."
          until status.empty?
            `kill #{pid} >/dev/null 2>&1`
            status = `ps -u #{Process.uid} | grep "#{pid} "`.scan(/ server\.[^\s]+/)
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
      
      server = if verbose
        Rack::Server.new(
          :app => self,
          :Port => @riddl_opts[:port],
          :environment => (@riddl_opts[:mode] == :debug ? 'development' : 'deployment'),
          :server => 'thin',
          :pid => File.expand_path(@riddl_opts[:basepath] + '/' + @riddl_opts[:pidfile])
        )
      else
        server = Rack::Server.new(
          :app => self,
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
      
      puts "Server (#{@riddl_opts[:url]}) started"
      server.start
    end #}}}

    def initialize(riddl,opts={},&blk)# {{{
      @riddl_opts = {}
      OPTS.each do |k,v|
        @riddl_opts[k] = opts.has_key?(k) ? opts[k] : v
      end

      if File.exists?(@riddl_opts[:basepath] + '/' + @riddl_opts[:conffile])
        eval(File.read(@riddl_opts[:basepath] + '/' + @riddl_opts[:conffile]))
      end
      @riddl_opts[:url] = @riddl_opts[:host] + ':' + @riddl_opts[:port].to_s

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
      dup._call(env)
    end# }}}

    def _call(env) #{{{
      Dir.chdir(@riddl_opts[:basepath]) if @riddl_opts[:basepath]

      time = Time.now unless @riddl_logger.nil?
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
        @riddl_message = @riddl.io_messages(@riddl_matching_path[0],@riddl_method,@riddl_parameters,@riddl_headers)

        if @riddl_env["HTTP_CONNECTION"] =~ /Upgrade/ && @riddl_env["HTTP_UPGRADE"] =~ /\AWebSocket\z/i
          @riddl_path = '/'
          #if @riddl.declaration? && @riddl_message. TODO
          #raise SpecificationError, 'RIDDL description does not conform to specification' unless @riddl.validate!
          instance_exec(info, &@riddl_interfaces[nil])
          return [-1, {}, []]
        else
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
            if get 'riddl-description-request'
              run Riddl::Utils::Description::XML, @riddl_description_string 
            else
              if @riddl.description?
                instance_exec(info, &@riddl_interfaces[nil])  
              elsif @riddl.declaration?
                ifs = @riddl_message.route? ? @riddl_message.route : [@riddl_message]
                ifs.each do |m|
                  b m.interface.base
                  # run Riddl::Utils::Description::Call, m.interface.base, m.interface.des.to_doc, m.interface.real_path(@riddl_pinfo)
                end
              end
            end
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
    def interface(name,&block)
      @riddl_interfaces[name] = block
    end

    def on(resource, &block)# {{{
      if @riddl_paths.empty? # default interface, when a description and "on" syntax in server
        @riddl_interfaces[nil] = block
        return
      end  

      @riddl_path << (@riddl_path == '/' ? resource : '/' + resource)

      ### only descend when there is a possibility that it holds the right path
      rp = @riddl_path.split('/')
      block.call(info) if @riddl_matching_path_pieces[rp.length-1] == rp.last
      @riddl_path = File.dirname(@riddl_path).gsub(/\/+/,'/')
    end# }}}

    def use(blk,*args)# {{{
      instance_eval(&blk)
    end# }}}

    def run(what,*args)# {{{
      return if @riddl_path == ''
      if what.class == Class && what.superclass == Riddl::WebSocketImplementation
        data = WebSocketParserData.new
        data.headers = {}
        data.request_path = @riddl_env['REQUEST_PATH'].to_s
        data.request_url = @riddl_env['REQUEST_URI'].to_s
        data.query_string = @riddl_env['QUERY_STRING'].to_s
        data.http_method = @riddl_env['REQUEST_METHOD']
        data.body = @riddl_env['rack.input'].read
        @riddl_env.each do |key, value| 
          if key.match(/HTTP_(.+)/) 
            data.headers[$1.downcase.gsub('_','-')] ||= value 
          end 
        end
        w = what.new(info(:a => args, :version => @riddl_env['HTTP_SEC_WEBSOCKET_VERSION']))
        w.io = Riddl::WebSocket.new(w, @riddl_env['thin.connection'])
        w.io.dispatch(data)
      end  
      if what.class == Class && what.superclass == Riddl::Implementation
        w = what.new(info(:a => args))
        response          = w.response
        headers           = w.headers
        @riddl_res.status = w.status

        response = (response.is_a?(Array) ? response : [response])
        headers  = (headers.is_a?(Array) ? headers : [headers])
        response.delete_if do |r|
          r.class != Riddl::Parameter::Simple && r.class != Riddl::Parameter::Complex
        end
        response.compact!
        if @riddl_process_out && @riddl_res.status == 200
          unless @riddl.check_message(response,headers,@riddl_message.out)
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
      if !@riddl_message.nil? && what.class == Hash && what.length == 1
        met, min = what.first
        @riddl_path == @riddl_matching_path[0] && min == @riddl_message.in.name && @riddl_method == met.to_s.downcase
      else  
        false
      end
    end  # }}}
    def post(min='*');   return false if     @riddl_message.nil?; @riddl_path == @riddl_matching_path[0] && min == @riddl_message.in.name && @riddl_method == 'post'   end
    def get(min='*');    return false if     @riddl_message.nil?; @riddl_path == @riddl_matching_path[0] && min == @riddl_message.in.name && @riddl_method == 'get'    end
    def delete(min='*'); return false if     @riddl_message.nil?; @riddl_path == @riddl_matching_path[0] && min == @riddl_message.in.name && @riddl_method == 'delete' end
    def put(min='*');    return false if     @riddl_message.nil?; @riddl_path == @riddl_matching_path[0] && min == @riddl_message.in.name && @riddl_method == 'put'    end
    def websocket;       return false unless @riddl_message.nil?; @riddl_path == @riddl_matching_path[0]                                                               end

    def resource(path=nil); return path.nil? ? '{}' : path end

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
      @riddl.declaration? ? @riddl : nil
    end# }}}

  end
end
