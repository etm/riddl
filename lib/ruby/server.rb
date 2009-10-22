require File.expand_path(File.dirname(__FILE__) + '/implementation')
require File.expand_path(File.dirname(__FILE__) + '/httpparser')
require File.expand_path(File.dirname(__FILE__) + '/httpgenerator')
require File.expand_path(File.dirname(__FILE__) + '/header')
require File.expand_path(File.dirname(__FILE__) + '/parameter')
require File.expand_path(File.dirname(__FILE__) + '/error')
require File.expand_path(File.dirname(__FILE__) + '/wrapper')

module Riddl
  class Server
    BOUNDARY = "Time_is_an_illusion._Lunchtime_doubly_so.0xriddldata"
    EOL = "\r\n"

    attr_reader :env, :req, :res

    def initialize(description,&blk)
      @description = Riddl::Wrapper::new(description)
      raise SpecificationError, 'No RIDDL description found.' unless @description.description?
      raise SpecificationError, 'RIDDL description does not conform to specification' unless @description.validate!
      @description.load_necessary_handlers!
      
      @norun = true
      @logger = nil
      @process_out = true 
      @cross_site_xhr = false
      @blk =  nil
      instance_eval(&blk)
      @norun = false

      @paths = @description.paths
    end

    def call(env)
      dup._call(env)
    end

    def _call(env)
      time = Time.now  unless @logger.nil?
      @pinfo = (env["PATH_INFO"] + '/').gsub(/\/+/,'/')
      @env = env
      @req = Rack::Request.new(env)
      @res = Rack::Response.new
      @log = @env['rack.errors']
      @riddl_path = @paths.find{ |e| e[1] =~ @pinfo }

      if @riddl_path
        @headers = {}
        @env.each do |h,v|
          @headers[$1] = v if h =~ /^HTTP_(.*)$/
        end
        @parameters = Riddl::HttpParser.new(
          @env['QUERY_STRING'],
          @env['rack.input'],
          @env['CONTENT_TYPE'],
          @env['CONTENT_LENGTH'],
          @env['HTTP_CONTENT_DISPOSITION'],
          @env['HTTP_CONTENT_ID'],
          @env['HTTP_RIDDL_TYPE']
        ).params
        @riddl_method = @env['REQUEST_METHOD'].downcase

        @riddl_message = @description.io_messages(@riddl_path[0],@riddl_method,@parameters,@headers)
        if @riddl_message.nil?
          if @env.has_key?('HTTP_ORIGIN') && @cross_site_xhr
            @res['Access-Control-Allow-Origin'] = @env['HTTP_ORIGIN']
            @res['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
            @res['Access-Control-Max-Age'] = '0'
            @res['Content-Length'] = '0'
            @res.status = 200
          else
            @log.puts "501: the #{@riddl_method} parameters are not matching anything in the description."
            @res.status = 501 # not implemented?!
          end  
        else
          @path = '/'
          instance_eval(&@blk)
          if @cross_site_xhr
            @res['Access-Control-Allow-Origin'] = '*'
            @res['Access-Control-Max-Age'] = '0'
          end
        end  
      else
        @log.puts "404: this resource for sure does not exist."
        @res.status = 404 # client requests wrong path
      end
      @logger.info(@env,@res,time) unless @logger.nil?
      @res.finish
    end
  
    def on(resource, &block)
      if @norun
        @blk = block if @blk.nil?
      else  
        @path << resource
        yield
        @path = (File.dirname(@path) + '/').gsub(/\/+/,'/')
      end  
    end

    def process_out(pout)
      @process_out = pout
    end
    def cross_site_xhr(csxhr)
      @cross_site_xhr = csxhr
    end
    def logger(lgr)
      @logger = lgr
    end

    def run(what,*args)
      return if @norun
      return if @path == ''
      if what.class == Class && what.superclass == Riddl::Implementation
        w = what.new(@headers,@parameters,@pinfo.sub(/\//,'').split('/'),@path.sub(/\//,'').split('/'),@env.reject{|k,v| k =~ /^rack\./},args)
        response    = w.response
        headers     = w.headers
        @res.status = w.status

        response = (response.class == Array ? response : [response])
        headers  = (headers.class == Array ? headers : [headers])
        if @process_out && @res.status == 200
          unless @description.check_message(response,headers,@riddl_message.out)
            @log.puts "500: the return for the #{@riddl_method} is not matching anything in the description."
            @res.status = 500
            return
          end  
        end
        if @res.status == 200
          @res.write HttpGenerator.new(response,@res).generate.read
        end  
        headers.each do |h|
          if h.class == Riddl::Header
            @res[h.name] = h.value
          end  
        end
      end
    end

    def method(what)
      return if @norun
      if what.class == Hash
        what.each do |met,min|
          return true if check(min) && @riddl_method == met.to_s.downcase
        end  
      end
      false
    end  
    def post(min='*'); return if @norun; check(min) && @riddl_method == 'post' end
    def get(min='*'); return if @norun; check(min) && @riddl_method == 'get' end
    def delete(min='*'); return if @norun; check(min) && @riddl_method == 'delete' end
    def put(min='*'); return if @norun; check(min) && @riddl_method == 'put' end
    def check(min)
       return if @norun
       @path == @riddl_path[0] && min == @riddl_message.in.name
    end

    def resource(path=nil); return if @norun; path.nil? ? '{}/' : path + '/' end
  end
end
