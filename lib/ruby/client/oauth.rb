require File.expand_path(File.dirname(__FILE__) + '/../httpgenerator')
require 'openssl'
require 'base64'

module Riddl
  class Client
    module OAuth
      DIGEST = OpenSSL::Digest::Digest.new('sha1')

      VERSION_MAJOR = 1
      VERSION_MINOR = 0

      def self::request_token(resource,parameters,realm,key,secret)
        signature_string = "POST&" + HttpGenerator::escape(resource.fullpath) + "&"

        sparams = []
        if parameters.class == Array
          parameters.each do |p|
            if p.class == Riddl::Parameter::Simple
              sparams << [HttpGenerator::escape(p.name),HttpGenerator::escape(p.value)]
            end
          end
        end

        oparams = []
        oparams << ["oauth_consumer_key",HttpGenerator::escape(key)]
        oparams << ["oauth_signature_method","HMAC-SHA1"]
        oparams << ["oauth_timestamp",Time.new.to_i.to_s]
        oparams << ["oauth_version","1.0"]
        oparams << ["oauth_nonce",(1..5).map{OpenSSL::Digest::SHA1.hexdigest(rand(10000).to_s)[0,8]}.join]

        params = (sparams + oparams).sort{|a,b|a[0]<=>b[0]}.map{ |e| 
          HttpGenerator::escape(e[0]) + '=' + HttpGenerator::escape(e[1])
        }.join('&')
        signature_string += HttpGenerator::escape(params)

        signature = OpenSSL::HMAC.digest(DIGEST,HttpGenerator::escape(secret)+'&',signature_string)
        signature = [signature].pack("m").gsub(/\n/, '')

        oparams << ["oauth_signature", HttpGenerator::escape(signature)]

        parameters << Riddl::Header.new('Authorization', "OAuth realm=\"#{realm}\"," + oparams.map{|e|e[0]+'='+"\"#{e[1]}\""}.join(','))
      end

    end
  end
end
