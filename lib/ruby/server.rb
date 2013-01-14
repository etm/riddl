require File.expand_path(File.dirname(__FILE__) + '/constants')
require File.expand_path(File.dirname(__FILE__) + '/websocket')
require File.expand_path(File.dirname(__FILE__) + '/implementation')
require File.expand_path(File.dirname(__FILE__) + '/httpparser')
require File.expand_path(File.dirname(__FILE__) + '/httpgenerator')
require File.expand_path(File.dirname(__FILE__) + '/header')
require File.expand_path(File.dirname(__FILE__) + '/parameter')
require File.expand_path(File.dirname(__FILE__) + '/error')
require File.expand_path(File.dirname(__FILE__) + '/wrapper')

require 'optparse'
require 'stringio'
require 'rack/content_length'
require 'rack/chunked'

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

        if @riddl_env["HTTP_CONNECTION"] =~ /Upgrade/ && @riddl_env["HTTP_UPGRADE"] =~ /\AWebSocket\z/i
          @riddl_path = '/'
          instance_exec(info, &@riddl_blk)
          return [-1, {}, []]
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
    end #}}}
  
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
        request = {}
        request['path']   = @riddl_env['REQUEST_PATH'].to_s 
        request['method'] = @riddl_env['REQUEST_METHOD'] 
        request['query']  = @riddl_env['QUERY_STRING'].to_s 
        request['Body']   = @riddl_env['rack.input'].read
        @riddl_env.each do |key, value| 
          if key.match(/HTTP_(.+)/) 
            request[$1.downcase.gsub('_','-')] ||= value 
          end 
        end
        w = what.new(info(:a => args, :version => @riddl_env['HTTP_SEC_WEBSOCKET_VERSION']))
        w.io = Riddl::WebSocket.new(w, @riddl_env['thin.connection'])
        w.io.dispatch(request)
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

    def check(min) # {{{
      return false if @riddl_message.nil? # for websockets no @riddl_message is set
      @riddl_path == @riddl_matching_path[0] && min == @riddl_message.in.name
    end # }}}

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
