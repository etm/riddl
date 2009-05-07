require ::File.dirname(__FILE__) + "/implementation"
require ::File.dirname(__FILE__) + "/httpparser"
require ::File.dirname(__FILE__) + "/httpgenerator"
require ::File.dirname(__FILE__) + "/parameter"
require ::File.dirname(__FILE__) + "/file"

module Riddl
  class Server
    BOUNDARY = "Time_is_an_illusion._Lunchtime_doubly_so.0xriddldata"
    EOL = "\r\n"

    attr_reader :env, :req, :res

    def initialize(description,&blk)
      @description = Riddl::File::open(description)
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
      pinfo = env["PATH_INFO"].sub(/\/*$/,'/').gsub(/\/+/,'/')
      @env = env
      @req = Rack::Request.new(env)
      @res = Rack::Response.new
      @riddl_path = @paths.find{ |e| e[1] =~ pinfo }
      if @riddl_path
        params = Riddl::HttpParser.new(
          @env['QUERY_STRING'],
          @env['rack.input'],
          @env['CONTENT_TYPE'],
          @env['CONTENT_LENGTH'],
          @env['HTTP_CONTENT_DISPOSITION'],
          @env['HTTP_CONTENT_ID']
        ).params
        @riddl_operation = @env['REQUEST_METHOD'].downcase
        begin
          @path = ''
          @riddl_message_in, @riddl_message_out = @description.get_message(@riddl_path[0],@riddl_operation,params)
          instance_eval(&@blk)
        rescue  
          @res.status = 404
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

    def run(what)
      if what.class == Class and what.superclass == Riddl::Implementation
        w = what.new
        @res.status = w.status
        if w.status == 200
          begin
            @res.write HttpGenerator.new(w.response,@res).generate.read
          rescue => e
            puts e 
            puts e.backtrace 
          end
        end  
      end
    end

    def method(what)
      if what.class == Hash
        what.each do |met,min|
          return true if check(min) && @riddl_operation == met.to_s.downcase
        end  
      end
      false
    end  
    def post(min); check(min) && @riddl_operation == 'post' end
    def get(min); check(min) && @riddl_operation == 'get' end
    def delete(min); check(min) && @riddl_operation == 'delete' end
    def put(min); check(min) && @riddl_operation == 'put' end
    def check(min)
       @path == @riddl_path[0] && min == @riddl_message_in
    end

    def resource(path=nil); path.nil? ? '{}/' : path + '/' end
  end
end
