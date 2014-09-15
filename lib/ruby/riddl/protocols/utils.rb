module Riddl
  module Protocols
    module Utils

      # Performs URI escaping so that you can construct proper
      # query strings faster.  Use this rather than the cgi.rb
      # version since it's faster. (%20 instead of + for improved standards conformance).
      def self.escape(s)
        s.to_s.dup.force_encoding('ASCII-8BIT').gsub(/([^a-zA-Z0-9_.-]+)/n) {
          '%'+$1.unpack('H2'*$1.size).join('%').upcase
        }
      end

      def self::unescape(s)
        return s if s.nil?                                                                                                                                                                                       
        s.force_encoding("ASCII-8BIT").tr('+', ' ').gsub(/((?:%[0-9a-fA-F]{2})+)/n){
          [$1.delete('%')].pack('H*')
        }.force_encoding('UTF-8')
      end

    end
  end
end
