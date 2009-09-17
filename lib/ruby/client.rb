require 'net/http'
require ::File.expand_path(::File.dirname(__FILE__) + "/file")
require ::File.expand_path(::File.dirname(__FILE__) + "/error")
require ::File.expand_path(::File.dirname(__FILE__) + "/httpgenerator")
require ::File.expand_path(::File.dirname(__FILE__) + '/httpparser')
require ::File.expand_path(::File.dirname(__FILE__) + "/header")
require 'pp'

module Riddl

  class Client
    def initialize(base, riddl=nil)
      @base = base.gsub(/\/+$/,'')
      @paths = nil
      @description = nil
      unless riddl.nil?
        @description = Riddl::File::new(riddl)
        @description.load_necessary_handlers!
        raise SpecificationError, 'No RIDDL description found.' unless @description.description?
        raise SpecificationError, 'RIDDL description does not conform to specification' unless @description.validate!
        raise SpecificationError, 'RIDDL description contains invalid resources' unless @description.valid_resources?
        @paths = @description.paths
      end
    end

    def resource(path="")
      Resource.new(@base,'/' + path + '/',@description)
    end

    class Resource
      def initialize(base,path,description)
        pinfo = path.gsub(/\/+/,'/')
        @description = description
        @riddl_path = @description.nil? ? pinfo : description.paths.find{ |e| e[1] =~ pinfo }
        if @riddl_path.nil?
          raise PathError, 'Path not found.'
        end  
        @url = base + pinfo
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
        unless @description.nil?
          riddl_message_in, riddl_message_out = @description.get_message(@riddl_path[0],riddl_method.downcase,parameters,headers)
          if riddl_message_in.nil? && riddl_message_out.nil?
            raise InputError, "Not a valid input to service."
          end
        end  
        url = URI.parse(@url)
        req = Riddl::Client::Request.new(riddl_method,url.path,parameters,headers)
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
            unless @description.nil?
              unless @description.check_message(response,res,riddl_message_out)
                raise OutputError, "Not a valid output from service."
              end 
            end  
          end  
        end
        return res.code, response
      end
      private :exec_request
    end  

    class Request < Net::HTTPGenericRequest
      def initialize(method, path, parameters, headers)
        super method, true, true, path, headers
        tmp = HttpGenerator.new(parameters,self).generate
        self.content_length = tmp.size
        self.body_stream = tmp
      end
    end

  end
end  
