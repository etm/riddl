require 'openssl'
require 'base64'
require 'securerandom'
require 'json'

module Riddl
  module Utils
    module OAuth2

      module Helper
        class Tokens #{{{
          def initialize(tfile)
            @tfile = tfile
            @changed = changed
            read
          end

          def [](name)
            read if changed != @changed
            @tokens[name]
          end

          def method_missing(name,*opts)
            @tokens.send(name,*opts)
          end

          def []=(name,value)
            @tokens[name] = value
            write
            nil
          end

          def changed
            if File.exists?(@tfile)
              File.stat(@tfile).mtime
            else
              @tokens = {}
              write
            end
          end

          def write
            EM.defer {
              File.write(@tfile, JSON::pretty_generate(@tokens)) rescue {}
            }
            @changed = changed
          end
          private :write

          def read
            @tokens = JSON::parse(File.read(@tfile)) rescue {}
          end
          private :read

          def delete(token)
            deleted = @tokens.delete(token)
            write
            deleted
          end

          def delete_by_user(user_id)
            deleted = @tokens.delete_if { |_, v| v == user_id }
            write
            deleted
          end
        end #}}}

        def self::header #{{{
          {
            :alg => 'HS256',
            :typ => 'JWT'
          }.to_json
        end #}}}

        def self::nonce
          SecureRandom::hex(32)
        end

        def self::payload(client_id) #{{{
          {
            :iss => client_id,
            :sub => nonce,
            :aud => client_id,
            :exp => Time.now.to_i + 3600
          }.to_json
        end #}}}

        def self::sign(secret, what) #{{{
          Base64::urlsafe_encode64 OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), secret, what)
        end #}}}

        def self::make_access_token(client_id, secret)# {{{
          h = Base64::urlsafe_encode64 header
          p = Base64::urlsafe_encode64 payload(client_id)
          s = sign(secret, "#{h}.#{p}")
          "#{h}.#{p}.#{s}"
        end# }}}
        def self::make_refresh_token(client_id, secret) # {{{
          token = Base64::urlsafe_encode64({
            :iss => client_id,
            :sub => nonce,
            :exp => Time.now.to_i + 7.884e6
          }.to_json)
          "#{token}.#{sign(secret,token)}"
        end# }}}
        def self::generate_optimistic_token(client_id, secret) #{{{
          t = make_access_token(client_id, secret)
          r = make_refresh_token(client_id, secret)
          [t, r]
        end #}}}

        def self::decrypt_with_shared_secret(data, secret) #{{{
          # extract initialization vector from encrypted data for further shenanigans
          iv, encr = data[0...16], data[16..-1]

          decipher = OpenSSL::Cipher::Cipher.new 'aes-256-cbc'
          decipher.decrypt

          decipher.key = Digest::SHA256.hexdigest secret
          decipher.iv = iv

          decipher.update(encr) + decipher.final rescue nil
        end #}}}
        def self::encrypt_with_shared_secret(data, secret) #{{{
          cipher = OpenSSL::Cipher::Cipher.new 'aes-256-cbc'
          cipher.encrypt

          key = Digest::SHA256.hexdigest secret
          iv = cipher.random_iv
          cipher.key = key
          cipher.iv = iv

           Base64::urlsafe_encode64(iv + cipher.update(data) + cipher.final) rescue nil
        end #}}}
      end
    end
  end
end
