require 'net/http'
require ::File.dirname(__FILE__) + "/httpgenerator.rb"
require ::File.dirname(__FILE__) + "/parameter.rb"

module Riddl

  class Client
    def initialize(base, riddl=nil)
      @base = base
    end

    def resource(path)
      Resource.new(@base + '/' + path)
    end

    class Resource
      def initialize(url)
        @url = url
      end  

      def get(parameters = [])
        request('GET',parameters)
      end
      def post(parameters = [])
        request('POST',parameters)
      end
      def put(parameters = [])
        request('PUT',parameters)
      end
      def delete(parameters = [])
        request('DELETE',parameters)
      end
      
      def request(method,parameters)
        url = URI.parse(@url)
        req = Riddl::Client::Request.new(method,url.path,parameters)
        res = Net::HTTP.start(url.host, url.port) do |http|
          http.request(req)
        end
        res.body
      end
      private :request
    end  

    class Request < Net::HTTPGenericRequest
      def initialize(method, path, parameters)
        super method, true, true, path, nil
        tmp = HttpGenerator.new(parameters,self).generate
        self.content_length = tmp.size
        self.body_stream = tmp
      end
    end

  end
end  
