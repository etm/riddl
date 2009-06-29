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
      @env = env
      @req = Rack::Request.new(env)
      @res = Rack::Response.new
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
          @env['HTTP_CONTENT_ID']
        ).params
        @riddl_method = @env['REQUEST_METHOD'].downcase

        @path = ''
        @riddl_message_in, @riddl_message_out = @description.get_message(@riddl_path[0],@riddl_method,@parameters,@headers)
        if @riddl_message_in.nil? && @riddl_message_out.nil?
          @res.status = 404
        else  
          instance_eval(&@blk)
        end  
      else
        @res.status = 404
      end
      @res.finish
    end
  
    def on(resource, &block)
      @path << (@path == '' ? '/' : resource)
      yield
      @path = ::File.dirname(@path)
    end

    def process_out(pout)
      @process_out = pout
    end

    def run(what)
      if what.class == Class and what.superclass == Riddl::Implementation
        w = what.new(@headers,@parameters,@pinfo.sub(/\//,'').split('/'))
        @res.status = w.status
        response = headers = nil
        if @process_out && w.status == 200
          response = (w.response.class == Array ? w.response : [w.response])
          headers = (w.headers.class == Array ? w.headers : [w.headers])
          unless @description.check_message(response,headers,@riddl_message_out)
            @res.status = 404
            return
          end  
        end
        if w.status == 200
          response = (w.response.class == Array ? w.response : [w.response]) unless response
          headers = (w.headers.class == Array ? w.headers : [w.headers]) unless headers
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
