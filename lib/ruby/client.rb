require 'net/http'
require File.expand_path(File.dirname(__FILE__) + '/wrapper')
require File.expand_path(File.dirname(__FILE__) + '/error')
require File.expand_path(File.dirname(__FILE__) + '/httpgenerator')
require File.expand_path(File.dirname(__FILE__) + '/httpparser')
require File.expand_path(File.dirname(__FILE__) + '/header')

module Riddl

  class Client
    def initialize(base, riddl=nil, protocol='GET')
      @base = base.nil? ? nil : base.gsub(/\/+$/,'')
      @path = ''
      @rpath = ''
      @wrapper = nil
      unless riddl.nil?
        @wrapper = Riddl::Wrapper::new(riddl,protocol)
        raise SpecificationError, 'No RIDDL description or declaration found.' if !@wrapper.description? && !@wrapper.declaration?
        raise SpecificationError, 'RIDDL does not conform to specification' unless @wrapper.validate!
        @wrapper.load_necessary_handlers!
      end
    end

    def self::location(base)
      new(base)
    end  
    def self::interface(base,riddl,protocol='RIDDL')
      new(base,riddl,protocol)
    end  
    def self::facade(riddl,protocol='GET')
      new(nil,riddl,protocol)
    end  

    def resource(path="")
      @rpath = path.gsub(/\/+/,'/')
      @path = @wrapper.nil? ? @rpath : @wrapper.paths.find{ |e| e[1] =~ @rpath }
      if @path.nil?
        raise PathError, 'Path not found.'
      end
      self
    end  

    def get(parameters = [])
      exec_request('GET',parameters)
    end
    def post(parameters = [])
      exec_request('POST',parameters)
    end
    def put(parameters = [])
      exec_request('PUT',parameters)
    end
    def delete(parameters = [])
      exec_request('DELETE',parameters)
    end
    def request(what)
      if what.class == Hash && what.length == 1
        what.each do |method,parameters| 
          return exec_request(method.to_s.upcase,parameters)
        end  
      end
      raise ArgumentError, "Hash with ONE method => parameters pair required"
    end  
    
    def exec_request(riddl_method,parameters)
      headers = {}
      parameters.delete_if do |p|
        if p.class == Riddl::Header
          headers[p.name.upcase] = "#{p.value}"
          true
        else
          false
        end  
      end
      unless @wrapper.nil?
        riddl_message = @wrapper.io_messages(@path,riddl_method.downcase,parameters,headers)
        if riddl_message.nil?
          raise InputError, "Not a valid input to service."
        end
      end  

      # when description
      #   uary = @base + @rpath in array
      # when declaration
      #   für jeden layer in der composition
      #     uray = @interface.base + ???

      url = URI.parse(@base + @rpath)
      req = Riddl::Client::Request.new(riddl_method,url.path,parameters,headers)
      res = response = nil
      Net::HTTP.start(url.host, url.port) do |http|
        http.request(req) do |res|
          bs = Parameter::Tempfile.new("RiddlBody")
          res.read_body(bs)
          bs.rewind
          p res['HTTP-CONTENT-ID']
          p res['CONTENT-DISPOSITION']
          p res['RIDDL-TYPE']
          p res['CONTENT-TYPE']
          bs.rewind

          response = Riddl::HttpParser.new(
            "",
            bs,
            res['CONTENT-TYPE'],
            res['CONTENT-LENGTH'],
            res['CONTENT-DISPOSITION'],
            res['HTTP-CONTENT-ID'],
            res['RIDDL-TYPE']
          ).params
          unless @wrapper.nil?
            unless @wrapper.check_message(response,res,riddl_message.out)
              raise OutputError, "Not a valid output from service."
            end 
          end  
        end  
      end
      return res.code, response
    end
    private :exec_request
  
    class Request < Net::HTTPGenericRequest
      def initialize(method, path, parameters, headers)
        path = path.strip == '' ? '/' : path
        super method, true, true, path, headers
        tmp = HttpGenerator.new(parameters,self).generate
        self.content_length = tmp.size
        self.body_stream = tmp
      end
    end
    
  end  

end  
