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
      @riddl_description = Riddl::Wrapper::new(description)
      raise SpecificationError, 'No RIDDL description found.' unless @riddl_description.description?
      raise SpecificationError, 'RIDDL description does not conform to specification' unless @riddl_description.validate!
      @riddl_description.load_necessary_handlers!
      
      @riddl_norun = true
      @riddl_logger = nil
      @riddl_process_out = true 
      @riddl_cross_site_xhr = false
      @riddl_blk =  nil
      instance_eval(&blk)
      @riddl_norun = false

      @riddl_paths = @riddl_description.paths
    end

    def call(env)
      dup._call(env)
    end

    def _call(env)
      time = Time.now  unless @riddl_logger.nil?
      @riddl_pinfo = env["PATH_INFO"].gsub(/\/+/,'/')
      @riddl_env = env
      @riddl_req = Rack::Request.new(env)
      @riddl_res = Rack::Response.new
      @riddl_log = @riddl_env['rack.errors']
      @riddl_matching_path = @riddl_paths.find{ |e| e[1] =~ @riddl_pinfo }

      if @riddl_matching_path
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

        @riddl_message = @riddl_description.io_messages(@riddl_matching_path[0],@riddl_method,@riddl_parameters,@riddl_headers)
        if @riddl_message.nil?
          if @riddl_env.has_key?('HTTP_ORIGIN') && @riddl_cross_site_xhr
            @riddl_res['Access-Control-Allow-Origin'] = @riddl_env['HTTP_ORIGIN']
            @riddl_res['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
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
          instance_exec(
            {
              :h => @riddl_headers, 
              :p => @riddl_parameters, 
              :r => @riddl_pinfo.sub(/\//,'').split('/'), 
              :m => @riddl_method, 
              :env => @riddl_env.reject{|k,v| k =~ /^rack\./}, 
              :match => @riddl_path.sub(/\//,'').split('/') 
            },
            &@riddl_blk
          )  
          if @riddl_cross_site_xhr
            @riddl_res['Access-Control-Allow-Origin'] = '*'
            @riddl_res['Access-Control-Max-Age'] = '0'
          end
        end  
      else
        @riddl_log.puts "404: this resource for sure does not exist."
        @riddl_res.status = 404 # client requests wrong path
      end
      @riddl_logger.info(@riddl_env,@riddl_res,time) unless @riddl_logger.nil?
      @riddl_res.finish
    end
  
    def on(resource, &block)
      if @riddl_norun
        @riddl_blk = block if @riddl_blk.nil?
      else  
        @riddl_path << (@riddl_path == '/' ? resource : '/' + resource)
        block.call(
          { :h => @riddl_headers, 
            :p => @riddl_parameters, 
            :r => @riddl_pinfo.sub(/\//,'').split('/'), 
            :m => @riddl_method, 
            :env => @riddl_env.reject{|k,v| k =~ /^rack\./}, 
            :match => @riddl_path.sub(/\//,'').split('/') 
          }
        )
        @riddl_path = File.dirname(@riddl_path).gsub(/\/+/,'/')
      end  
    end

    def process_out(pout)
      @riddl_process_out = pout
    end
    def cross_site_xhr(csxhr)
      @riddl_cross_site_xhr = csxhr
    end
    def logger(lgr)
      @riddl_logger = lgr
    end

    def run(what,*args)
      return if @riddl_norun
      return if @riddl_path == ''
      if what.class == Class && what.superclass == Riddl::Implementation
        w = what.new(
          { :h => @riddl_headers, 
            :p => @riddl_parameters, 
            :r => @riddl_pinfo.sub(/\//,'').split('/'), 
            :m => @riddl_method, 
            :env => @riddl_env.reject{|k,v| k =~ /^rack\./}, 
            :match => @riddl_path.sub(/\//,'').split('/'),
            :a => args
          }
        )
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
    end

    def method(what)
      return if @riddl_norun
      if what.class == Hash
        what.each do |met,min|
          return true if check(min) && @riddl_method == met.to_s.downcase
        end  
      end
      false
    end  
    def post(min='*'); return if @riddl_norun; check(min) && @riddl_method == 'post' end
    def get(min='*'); return if @riddl_norun; check(min) && @riddl_method == 'get' end
    def delete(min='*'); return if @riddl_norun; check(min) && @riddl_method == 'delete' end
    def put(min='*'); return if @riddl_norun; check(min) && @riddl_method == 'put' end
    def check(min)
      @riddl_path == @riddl_matching_path[0] && min == @riddl_message.in.name
    end

    def resource(path=nil); return if @riddl_norun; path.nil? ? '{}' : path end
  end
end
