require File.expand_path(File.dirname(__FILE__) + '/../../protocols/http/generator')
require 'openssl'
require 'base64'

module Riddl
  module Roles
    module OAuth
      DIGEST = OpenSSL::Digest::Digest.new('sha1')
      VERSION_MAJOR = 1
      VERSION_MINOR = 0

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
            k, v = Protocols::HTTP::Parser::unescape(p).split('=', 2)
            @provided[k.to_sym] = v
          end
        end
      end

      def self::sign(fullpath,method,parameters,headers,options)
        signature_string = method.upcase + "&" + Protocols::HTTP::Generator::escape(fullpath) + "&"

        sparams = []
        if parameters.class == Array
          parameters.each do |p|
            if p.class == Riddl::Parameter::Simple
              sparams << [Protocols::HTTP::Generator::escape(p.name),Protocols::HTTP::Generator::escape(p.value)]
            end
          end
        end

        oparams = []
        oparams << ["oauth_consumer_key",Protocols::HTTP::Generator::escape(options[:consumer_key])]
        oparams << ["oauth_signature_method","HMAC-SHA1"]
        oparams << ["oauth_timestamp",Time.new.to_i.to_s]
        oparams << ["oauth_version","1.0"]
        oparams << ["oauth_nonce",Protocols::HTTP::Generator::escape(OpenSSL::Digest::SHA1.hexdigest(rand(10000).to_s)[0...32])]
        oparams << ["oauth_token",Protocols::HTTP::Generator::escape(options[:token])] if options[:token]
        oparams << ["oauth_verifier",Protocols::HTTP::Generator::escape(options[:verifier])] if options[:verifier]

        params = (sparams + oparams).sort{|a,b|a[0]<=>b[0]}.map{ |e| e[0] + '=' + e[1] }.join('&')
        signature_string += Protocols::HTTP::Generator::escape(params)

        signature = OpenSSL::HMAC.digest(DIGEST,"#{Protocols::HTTP::Generator::escape(options[:consumer_secret])}&#{Protocols::HTTP::Generator::escape(options[:token_secret])}",signature_string)
        signature = [signature].pack("m").gsub(/\n/, '')

        oparams << ["oauth_signature", Protocols::HTTP::Generator::escape(signature)]

        oparams.unshift(["realm", Protocols::HTTP::Generator::escape(options[:realm])]) if options[:realm]

        headers['Authorization'] = 'OAuth ' + oparams.map{|e|e[0]+'='+"\"#{e[1]}\""}.join(', ')
      end

    end  

  end
end
