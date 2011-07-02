require File.expand_path(File.dirname(__FILE__) + '/http%3A%2F%2Foauth.net%2F1.0/base')

module Riddl
  module Roles
    module OAuth

      module AccessToken
        WANTED = [:consumer_key, :consumer_secret, :token, :token_secret, :verifier]

        def self::after(fullpath,method,code,response,headers,options)
          if code == 200
            Riddl::Roles::OAuth::Response.new(response[0].value.read)
          else  
            response
          end
        end

        def self::before(fullpath,method,parameters,headers,options)
          unless WANTED.all?{ |e| options.has_key?(e) }
            raise ArgumentError, "Riddl::Options have to include: #{WANTED.join(', ')}"
          end
          Riddl::Roles::OAuth::sign(fullpath,method,parameters,headers,options)
        end
      end  

    end
  end
end

Riddl::Roles::add("http://oauth.net/1.0/access_token",Riddl::Roles::OAuth::AccessToken)
