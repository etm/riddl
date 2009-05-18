require 'net/http'
require ::File.dirname(__FILE__) + "/httpgenerator"
require ::File.dirname(__FILE__) + "/header"
require ::File.dirname(__FILE__) + "/parameter"

module Riddl

  class Client
    def initialize(base, riddl=nil)
      @base = base
    end

    def resource(path="")
      Resource.new(@base + '/' + path)
    end

    class Resource
      def initialize(url)
        @url = url
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
          what.each { |method,parameters| return exec_request(method.to_s.upcase,parameters) }
        end
        raise ArgumentError, "Hash with ONE method => parameters pair required"
      end  
      
      def exec_request(method,parameters)
        url = URI.parse(@url)
        req = Riddl::Client::Request.new(method,url.path,parameters)
        res = Net::HTTP.start(url.host, url.port) do |http|
          http.request(req)
        end
        res.body
      end
      private :exec_request
    end  

    class Request < Net::HTTPGenericRequest
      def initialize(method, path, parameters)
        headers = {}
        parameters.delete_if do |p|
          if p.class == Riddl::Header
            headers[p.name] = "#{p.value}"
            true
          else
            false
          end  
        end
        super method, true, true, path, headers
        tmp = HttpGenerator.new(parameters,self).generate
        self.content_length = tmp.size
        self.body_stream = tmp
      end
    end

  end
end  
