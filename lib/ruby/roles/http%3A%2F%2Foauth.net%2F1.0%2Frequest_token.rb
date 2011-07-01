require File.expand_path(File.dirname(__FILE__) + '/../httpgenerator')
require 'openssl'
require 'base64'

module Riddl
  module Roles
    module OAuth
      DIGEST = OpenSSL::Digest::Digest.new('sha1')
      VERSION_MAJOR = 1
      VERSION_MINOR = 0
      WANTED = [:key, :realm, :secret]

      class RequestToken
        class Response
          def method_missing(name)
            @provided[name]
          end

          def items
            @provided.keys
          end

          def initialize(qs)
            @provided = {}
            (qs || '').split(/[&] */n).each do |p|
              k, v = HttpParser::unescape(p).split('=', 2)
              @provided[k.to_sym] = v
            end
          end
        end

        def self::after(fullpath,method,code,response,headers,options)
          if code == 200
            Response.new(response[0].value.read)
          else  
            response
          end
        end

        def self::before(fullpath,method,parameters,headers,options)
          unless WANTED.all?{ |e| options.has_key?(e) }
            raise ArgumentError, "Riddl::Options have to include: #{WANTED.join(', ')}"
          end

          signature_string = "POST&" + HttpGenerator::escape(fullpath) + "&"

          sparams = []
          if parameters.class == Array
            parameters.each do |p|
              if p.class == Riddl::Parameter::Simple
                sparams << [HttpGenerator::escape(p.name),HttpGenerator::escape(p.value)]
              end
            end
          end

          oparams = []
          oparams << ["oauth_consumer_key",HttpGenerator::escape(options[:key])]
          oparams << ["oauth_signature_method","HMAC-SHA1"]
          oparams << ["oauth_timestamp",Time.new.to_i.to_s]
          oparams << ["oauth_version","1.0"]
          oparams << ["oauth_nonce",(1..5).map{OpenSSL::Digest::SHA1.hexdigest(rand(10000).to_s)[0,8]}.join]

          params = (sparams + oparams).sort{|a,b|a[0]<=>b[0]}.map{ |e| 
            HttpGenerator::escape(e[0]) + '=' + HttpGenerator::escape(e[1])
          }.join('&')
          signature_string += HttpGenerator::escape(params)

          signature = OpenSSL::HMAC.digest(DIGEST,HttpGenerator::escape(options[:secret])+'&',signature_string)
          signature = [signature].pack("m").gsub(/\n/, '')

          oparams << ["oauth_signature", HttpGenerator::escape(signature)]

          headers['Authorization'] = "OAuth realm=\"#{options[:realm]}\"," + oparams.map{|e|e[0]+'='+"\"#{e[1]}\""}.join(',')
        end
      end  

    end
  end
end

Riddl::Roles::add("http://oauth.net/1.0/request_token",Riddl::Roles::OAuth::RequestToken)
