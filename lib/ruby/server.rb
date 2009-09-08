require ::File.dirname(__FILE__) + '/implementation'
require ::File.dirname(__FILE__) + '/httpparser'
require ::File.dirname(__FILE__) + '/httpgenerator'
require ::File.dirname(__FILE__) + '/header'
require ::File.dirname(__FILE__) + '/parameter'
require ::File.dirname(__FILE__) + '/error'
require ::File.dirname(__FILE__) + '/file'
require 'pp'

module Riddl
  class Server
    BOUNDARY = "Time_is_an_illusion._Lunchtime_doubly_so.0xriddldata"
    EOL = "\r\n"

    attr_reader :env, :req, :res

    def initialize(description,&blk)
      @description = Riddl::File::new(description)
      @description.load_necessary_handlers!
      raise SpecificationError, 'No RIDDL description found.' unless @description.description?
      raise SpecificationError, 'RIDDL description does not conform to specification' unless @description.validate!
      raise SpecificationError, 'RIDDL description contains invalid resources' unless @description.valid_resources?
      @paths = @description.paths
      @blk = blk
    end

    def call(env)
      dup._call(env)
    end

    def _call(env)
      @pinfo = (env["PATH_INFO"] + '/').gsub(/\/+/,'/')
      @process_out = true
      @cross_site_xhr = false
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

        @path = ''
        @riddl_message_in, @riddl_message_out = @description.get_message(@riddl_path[0],@riddl_method,@parameters,@headers)
        if @riddl_message_in.nil? && @riddl_message_out.nil?
          @log.puts "501: the #{@riddl_method} parameters are not matching anything in the description."
          @res.status = 501 # not implemented?!
        else  
          instance_eval(&@blk)
        end  
      else
        @log.puts "404: this resource for sure does not exist."
        @res.status = 404 # client requests wrong path
      end
      @res.finish
    end
  
    def on(resource, &block)
      @path << (@path == '' ? '/' : resource)
      yield
      @path = (::File.dirname(@path) + '/').gsub(/\/+/,'/')
    end

    def process_out(pout)
      @process_out = pout
    end
    def cross_site_xhr(csxhr)
      @cross_site_xhr = csxhr
    end

    def run(what,*args)
      if what.class == Class && what.superclass == Riddl::Implementation
        w = what.new(@headers,@parameters,@pinfo.sub(/\//,'').split('/'),@path.sub(/\//,'').split('/'),@env.reject{|k,v| k =~ /^rack\./},args)
        response    = w.response
        headers     = w.headers
        @res.status = w.status
        @res['Access-Control'] = 'allow <*>' if @cross_site_xhr

        response = (response.class == Array ? response : [response])
        headers  = (headers.class == Array ? headers : [headers])
        if @process_out && @res.status == 200
          unless @description.check_message(response,headers,@riddl_message_out)
            @log.puts "500: the return for the #{@riddl_method} is not matching anything in the description."
            @res.status = 500
            return
          end  
        end
        if @res.status == 200
          @res.write HttpGenerator.new(response,@res).generate.read
          headers.each do |h|
            if h.class == Riddl::Header
              @res[h.name] = h.value
            end  
          end
        end  
      end
    end

    def method(what)
      if what.class == Hash
        what.each do |met,min|
          return true if check(min) && @riddl_method == met.to_s.downcase
        end  
      end
      false
    end  
    def post(min); check(min) && @riddl_method == 'post' end
    def get(min); check(min) && @riddl_method == 'get' end
    def delete(min); check(min) && @riddl_method == 'delete' end
    def put(min); check(min) && @riddl_method == 'put' end
    def check(min)
       @path == @riddl_path[0] && min == @riddl_message_in
    end

    def resource(path=nil); path.nil? ? '{}/' : path + '/' end
  end
end
