module Riddl
  module Handlers
    class OAuthRequestToken
      D = '&;'
      WANTED = [:oauth_token,:oauth_token_secret]

      def self::handle(what,hinfo)
        provided = []
        qs = what.read
        (qs || '').split(/[#{D}] */n).each do |p|
          k, v = HttpParser::unescape(p).split('=', 2)
          provided << k.to_sym
        end
        WANTED.all?{ |e| provided.include?(e) }
      end
    end
  end  
end  

Riddl::Handlers::add("http://riddl.org/ns/handlers/oauth_request_token",Riddl::Handlers::OAuthRequestToken)
