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
    WS_HANDSHAKE = "HTTP/1.1 101 Web Socket Protocol Handshake" + EOL +
                   "Upgrade: WebSocket" + EOL +
                   "Connection: Upgrade" + EOL +
                   "WebSocket-Origin: %s" + EOL +
                   "WebSocket-Location: %s" + EOL + EOL

    def initialize(riddl,&blk)# {{{
      @riddl_norun = true
      @riddl_logger = nil
      @riddl_process_out = true 
      @riddl_cross_site_xhr = false
      @accessible_description = false
      @riddl_blk =  nil
      instance_eval(&blk)
      @riddl_norun = false

      riddl = Riddl::Wrapper.new(riddl)
      if riddl.description?
        @riddl_description = riddl
        raise SpecificationError, 'RIDDL description does not conform to specification' unless @riddl_description.validate!
      elsif riddl.declaration?
        @riddl_declaration = riddl
        raise SpecificationError, 'RIDDL declaration does not conform to specification' unless @riddl_declaration.validate!
        @riddl_description_string = riddl.declaration.description_xml(@accessible_description)
        @riddl_description = Riddl::Wrapper.new(@riddl_description_string)
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

        if @riddl_env["HTTP_CONNECTION"] =~ /\AUpgrade\z/ && @riddl_env["HTTP_UPGRADE"] =~ /\AWebSocket\z/ && @riddl_env["HTTP_ORIGIN"] && @riddl_env["HTTP_HOST"]
          @riddl_env["rack.io"].write(WS_HANDSHAKE % [@riddl_env["HTTP_ORIGIN"], ws_location])
          @riddl_env["rack.io"].flush

          @riddl_path = '/'
          @riddl_res.status = 404
          instance_exec(info, &@riddl_blk)  
        else
          @riddl_message = @riddl_description.io_messages(@riddl_matching_path[0],@riddl_method,@riddl_parameters,@riddl_headers)
          if @riddl_message.nil?
            if @riddl_env.has_key?('HTTP_ORIGIN') && @riddl_cross_site_xhr
              @riddl_res['Access-Control-Allow-Origin'] = '*'
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
        w = what.new(info(:a => args, :io => @riddl_env['rack.io']))
        w.onopen
        while data = ws_read
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
    def post(min='*'); return if @riddl_norun; check(min) && @riddl_method == 'post' end
    def get(min='*'); return if @riddl_norun; check(min) && @riddl_method == 'get' end
    def delete(min='*'); return if @riddl_norun; check(min) && @riddl_method == 'delete' end
    def put(min='*'); return if @riddl_norun; check(min) && @riddl_method == 'put' end
    def websocket; return if @riddl_norun; @riddl_path == @riddl_matching_path[0] end

    def check(min)# {{{
      return false unless @riddl_message # for websockets no @riddl_message is set
      @riddl_path == @riddl_matching_path[0] && min == @riddl_message.in.name
    end# }}}

    def resource(path=nil); return if @riddl_norun; path.nil? ? '{}' : path end

    def info(other={})# {{{
      { :h => @riddl_headers, 
        :p => @riddl_parameters, 
        :r => @riddl_pinfo.sub(/\//,'').split('/'), 
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

  private
    def ws_location
      host   = @riddl_env['SERVER_NAME']
      scheme = @riddl_env['rack.url_scheme'] == "https" ? "wss" : "ws"
      path   = @riddl_env['REQUEST_URI']
      port   = @riddl_env['SERVER_PORT']
      
      rv = "#{scheme}://#{host}"
      if (scheme == "wss" && port != 443) || (scheme == "ws" && port != 80)
        rv << ":#{port}"
      end
      rv << path
    end

    def ws_read
      if packet = @riddl_env['rack.io'].gets("\xff")
        if !(packet =~ /\A\x00(.*)\xff\z/nm)
          raise(WebSocket::Error, "input must start with \\x00 and end with \\xff")
        end
        $1.respond_to?(:force_encoding) ? $1.force_encoding('UTF-8') : $1
      else
        nil
      end
    end
  end
end
