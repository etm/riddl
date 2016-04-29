require File.expand_path(File.dirname(__FILE__) + '/oauth2-helper')

module Riddl
  module Utils
    module OAuth2
      
      module UnivieBearer
        def self::implementation(client_id, client_secret, access_tokens)
          Proc.new do
						run CheckAuth, client_id, client_secret, access_tokens if get
          end
        end  

				class CheckAuth < Riddl::Implementation
					def response
						client_id = @a[0]
						client_secret = @a[1]
						access_tokens = @a[2]
						if @h['AUTHORIZATION']
							token = @h['AUTHORIZATION'].sub(/^Bearer /, '')

							data, _, signature = token.rpartition '.'
							expected_sign = Riddl::Utils::OAuth2::Helper::sign(client_id + ':' + client_secret, data)

							if !access_tokens.key? token
								@status = 403
								return Riddl::Parameter::Complex.new('data', 'application/json', {
									:error => 'Unknown token'
								}.to_json)
							elsif signature != expected_sign
								@status = 403
								return Riddl::Parameter::Complex.new('data', 'application/json', {
									:error => 'Invalid token, you bad boy'
								}.to_json)
							end

							header_claims, payload_claims = data.split('.').map { |v| Base64::urlsafe_decode64 v }
							payload_claims = JSON::parse payload_claims

							if header_claims != Riddl::Utils::OAuth2::Helper::header
								@status = 401
								return Riddl::Parameter::Complex.new('data', 'application/json', {
									:error => 'Invalid header claims'
								}.to_json)
							elsif payload_claims['exp'] <= Time.now.to_i
								@status = 403
								return Riddl::Parameter::Complex.new('data', 'application/json', {
									:error => 'Expired token'
								}.to_json)
							elsif !payload_claims['aud'].split(',').map(&:strip).include? client_id
								# XXX: ein token für mehrere clients gültig? lookup?
								@status = 403
								return Riddl::Parameter::Complex.new('data', 'application/json', {
									:error => 'Token is not valid for this application'
								}.to_json)
							end

							@headers << Riddl::Header.new('AUTHORIZATION_BEARER', access_tokens[token])
						end

						@p
					end
				end
			end

      module UnivieApp
        def self::implementation(client_id, client_secret, access_tokens, refresh_tokens)
          Proc.new do
            on resource 'verify' do
              run VerifyIdentity, access_tokens, refresh_tokens, client_id, client_secret if post 'verify_in'
            end
            on resource 'token' do
              run RefreshToken, access_tokens, refresh_tokens, client_id, client_secret if post 'refresh_token_in'
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
            access_tokens.set(token, user_id, 3600)
            refresh_tokens.set(refresh_token, token, 7776000)

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
            refresh_tokens.delete_by_value(token)
          end
        end

        class RevokeUserFlow < Riddl::Implementation
          def response
            user_id = @p[0].value
            access_tokens = @a[0]
            refresh_tokens = @a[1]

            token = access_tokens.delete_by_value user_id
            refresh_tokens.delete_by_value token
          end
        end

        class RefreshToken < Riddl::Implementation
          def response
            refresh_token = @p[1].value
            access_tokens = @a[0]
            refresh_tokens = @a[1]
            client_id = @a[2]
            client_secret = @a[3]

            token, _ = refresh_token.split '.'
            token_data = JSON::parse(Base64::urlsafe_decode64 token)

            if token_data['iss'] != client_id
              @status = 401
              return Riddl::Parameter::Complex.new('data', 'application/json', {
                :error => 'Token must be refreshed by issuer.'
              }.to_json)
            elsif refresh_tokens[refresh_token].nil? || token_data['exp'] <= Time.now.to_i
              @status = 403
              puts "i dont know #{refresh_token}", "#{refresh_tokens[refresh_token]}"
              return Riddl::Parameter::Complex.new('data', 'application/json', {
                :error => 'Invalid refresh token.'
              }.to_json)
            end

            old_token = refresh_tokens[refresh_token]
            user = access_tokens.delete old_token

            token = Riddl::Utils::OAuth2::Helper::make_access_token(client_id, client_id + ':' + client_secret)

            access_tokens.set(token,user,3600)
            refresh_tokens.set(refresh_token, token, 7776000)

            Riddl::Parameter::Complex.new('data', 'application/json', { :token => token }.to_json)
          end
        end
      end

    end  
  end  
end
