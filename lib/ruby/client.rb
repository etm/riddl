require 'net/http'
require File.expand_path(File.dirname(__FILE__) + '/wrapper')
require File.expand_path(File.dirname(__FILE__) + '/error')
require File.expand_path(File.dirname(__FILE__) + '/httpgenerator')
require File.expand_path(File.dirname(__FILE__) + '/httpparser')
require File.expand_path(File.dirname(__FILE__) + '/header')

module Riddl

  class Client
    #{{{
    def initialize(base, riddl=nil, protocol='GET')
      @base = base.nil? ? nil : base.gsub(/\/+$/,'')
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
      Resource.new(@base,@wrapper,path)
    end
    def get(parameters = []);    resource('/').get(parameters);    end
    def post(parameters = []);   resource('/').post(parameters);   end
    def put(parameters = []);    resource('/').put(parameters);    end
    def delete(parameters = []); resource('/').delete(parameters); end
    def request(what)            resource('/').request(what);      end
    #}}}

    class Resource
      #{{
      def initialize(base,wrapper,path)
        @base = base
        @wrapper = wrapper
        @rpath = "/#{path}".gsub(/\/+/,'/')
        @path = if @wrapper.nil?
          @rpath
        else
          @path = @wrapper.paths.find{ |e| e[1] =~ @rpath }
          raise PathError, 'Path not found.' if @path.nil?
          @path[0]
        end
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

        qparams = []
        parameters.delete_if do |p|
          if p.class == Riddl::Parameter::Simple && p.type == :query
            qparams << HttpGenerator::escape(p.name) + '=' + HttpGenerator::escape(p.value)
            true
          else
            false
          end
        end

        if @wrapper.nil? || @wrapper.description?
          res, response = make_request(@base + @rpath,riddl_method,parameters,headers,qparams)
          unless @wrapper.nil?
            unless @wrapper.check_message(response,res,riddl_message.out)
              raise OutputError, "Not a valid output from service."
            end
          end
          return res.code.to_i, response
        end

        if !wrapper.nil? && @wrapper.declaration?
          if riddl_message.route.nil?
            res, response = make_request(@rpath,riddl_method,parameters,headers)
            unless @wrapper.check_message(response,res,riddl_message.out)
              raise OutputError, "Not a valid output from service."
            end
            return res.code.to_i, response
          else
            # loop through route
          end
        end
      end
      private :exec_request

      def make_request(url,riddl_method,parameters,headers,qparams)
        url = URI.parse(url)
        qs = qparams.join('&')
        req = Riddl::Client::Request.new(riddl_method,url.path,parameters,headers,qs)
        res = response = nil
        Net::HTTP.start(url.host, url.port) do |http|
          http.request(req) do |res|
            bs = Parameter::Tempfile.new("RiddlBody")
            res.read_body(bs)
            bs.rewind

            response = Riddl::HttpParser.new(
              "",
              bs,
              res['CONTENT-TYPE'],
              res['CONTENT-LENGTH'],
              res['CONTENT-DISPOSITION'],
              res['CONTENT-ID'],
              res['RIDDL-TYPE']
            ).params
          end
        end
        return res, response
      end
      private :make_request
      #}}}
    end

    class Request < Net::HTTPGenericRequest
      #{{{
      def initialize(method, path, parameters, headers, qs)
        path = path.strip == '' ? '/' : path
        path += "?#{qs}" unless qs == ''
        super method, true, true, path, headers
        tmp = HttpGenerator.new(parameters,self).generate(:input)
        self.content_length = tmp.size
        self.body_stream = tmp
      end
      #}}}
    end
  end

end
