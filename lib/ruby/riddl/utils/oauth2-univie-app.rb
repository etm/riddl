require File.expand_path(File.dirname(__FILE__) + '/oauth2-helper')

module Riddl
  module Utils
    module OAuth2

      module UnivieApp
        def self::implementation(client_id, client_secret, access_tokens, refresh_tokens)
          unless access_tokens.is_a?(Riddl::Utils::OAuth2::Helper::Tokens) && refresh_tokens.is_a?(Riddl::Utils::OAuth2::Helper::Tokens) && client_id.is_a?(String) && client_secret.is_a?(String)
            raise "client_id, client_secret or token storage not available."
          end
          Proc.new do
            on resource 'verify' do
              run VerifyIdentity, access_tokens, refresh_tokens, client_id, client_secret if post 'verify_in'
            end
            on resource 'token' do
              run RefreshToken, access_tokens, refresh_tokens if post 'refresh_token_in'
            end
            on resource 'revoke' do
              run RevokeTokenFlow, access_tokens, refresh_tokens if get 'revoke_token_in'
              run RevokeUserFlow, access_tokens, refresh_tokens if get 'revoke_user_in'
            end
          end
        end  

        class VerifyIdentity < Riddl::Implementation
          def response
            code = Base64::urlsafe_decode64 @p[0].value
            access_tokens = @a[0]
            refresh_tokens = @a[1]
            client_id = @a[2]
            client_secret = @a[3]

            client_pass   = "#{client_id}:#{client_secret}"
            user_id, decrypted            = Riddl::Utils::OAuth2::Helper::decrypt_with_shared_secret(code, client_pass).split(':', 2)
            token, refresh_token          = Riddl::Utils::OAuth2::Helper::generate_optimistic_token(client_id, client_pass)
            access_tokens[token]          = user_id
            refresh_tokens[refresh_token] = token

            json_response = {
              :access_token => token,
              :refresh_token => refresh_token,
              :code => Base64.urlsafe_encode64(decrypted)
            }.to_json

            Riddl::Parameter::Complex.new('data', 'application/json', json_response)
          end
        end

        class RevokeTokenFlow < Riddl::Implementation
          def response
            token = @p[0].value
            access_tokens = @a[0]
            refresh_tokens = @a[1]

            access_tokens.delete(token)
            refresh_tokens.delete_by_token(token)
          end
        end

        class RevokeUserFlow < Riddl::Implementation
          def response
            user_id = @p[0].value
            access_tokens = @a[0]
            refresh_tokens = @a[1]

            token = access_tokens.delete_by_user user_id
            refresh_tokens.delete_by_token token
          end
        end
      end

    end  
  end  
end
