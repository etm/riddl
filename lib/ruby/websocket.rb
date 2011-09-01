require 'base64'
require 'digest/sha1'
require 'bindata'

module Riddl

  module WebSocket
    class Error < RuntimeError; end

    HANDSHAKE_08 = "HTTP/1.1 101 Switching Protocols" + EOL +
                   "Upgrade: websocket" + EOL +
                   "Connection: Upgrade" + EOL +
                   "Sec-WebSocket-Accept: %s" + EOL + EOL

    HANDSHAKE_00 = "HTTP/1.1 101 Web Socket Protocol Handshake" + EOL +
                   "Upgrade: WebSocket" + EOL +
                   "Connection: Upgrade" + EOL +
                   "Sec-WebSocket-Origin: %s" + EOL +
                   "Sec-WebSocket-Location: %s" + EOL + EOL +
                   "%s"

    def self::handshake(env)
      if env["HTTP_SEC_WEBSOCKET_ORIGIN"] && env["HTTP_SEC_WEBSOCKET_KEY"]
        version = env["HTTP_SEC_WEBSOCKET_VERSION"].to_i
        sec = env["HTTP_SEC_WEBSOCKET_KEY"].strip
        key = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
        env["rack.io"].write(HANDSHAKE_08 % [security_digest_08(sec,key)])
      elsif env["HTTP_ORIGIN"] && env["HTTP_SEC_WEBSOCKET_KEY1"] && env["HTTP_SEC_WEBSOCKET_KEY2"]
        version = 0
        sec1 = env["HTTP_SEC_WEBSOCKET_KEY1"]
        sec2 = env["HTTP_SEC_WEBSOCKET_KEY2"]
        key  = env["rack.input"].read(8)
        env["rack.io"].write(HANDSHAKE_00 % [env["HTTP_ORIGIN"], location(env), security_digest_00(sec1,sec2,key)])
      end  
      env["rack.io"].flush
      version
    end

    def self::send(io,version,data,opcode=0x1)
      if version < 7 
        data = data.respond_to?(:force_encoding) ? data.dup.force_encoding("ASCII-8BIT") : data
        io.write("\x00#{data}\xff")
      elsif version >= 7 
        #   0x0 - continuation
        #   0x1 - text frame (base64 encode buf)
        #   0x2 - binary frame (use raw buf)
        #   0x8 - connection close
        #   0x9 - ping
        #   0xA - pong
        #   0x0f - FIN

        b1 = 0x80 | (opcode & 0x0f)
        len = data.length

        header = if len <= 125
          BinData::Uint8be.new(b1).to_binary_s +  BinData::Uint8be.new(len).to_binary_s
        elsif len > 125 && len < 65536
          BinData::Uint8be.new(b1).to_binary_s +  BinData::Uint8be.new(126).to_binary_s + BinData::Uint16be.new(len).to_binary_s 
        elsif len >= 65536
          BinData::Uint8be.new(b1).to_binary_s +  BinData::Uint8be.new(127).to_binary_s + BinData::Uint64be.new(len).to_binary_s 
        end

        io.write header + data
      end
      io.flush
    end

    ################

    def self::security_digest_08(key1, key2)
      return Base64::encode64(Digest::SHA1.digest(key1+key2)).tr("\n","")
    end

    ################

    def self::security_digest_00(key1, key2, key3)
      bytes1 = key_to_bytes(key1)
      bytes2 = key_to_bytes(key2)
      return Digest::MD5.digest(bytes1 + bytes2 + key3)
    end

    def self::key_to_bytes(key)
      num = key.gsub(/\D/n, '').to_i() / key.scan(/ /).size
      return [num].pack("N")
    end

    def self::location(env)
      host   = env['SERVER_NAME']
      scheme = env['rack.url_scheme'] == "https" ? "wss" : "ws"
      path   = env['REQUEST_URI']
      port   = env['SERVER_PORT']
      
      rv = "#{scheme}://#{host}"
      if (scheme == "wss" && port != 443) || (scheme == "ws" && port != 80)
        rv << ":#{port}"
      end
      rv << path
    end

    ################

    def self::read(io,version)
      if version < 7 
        if packet = io.gets("\xff")
          return nil if (packet == "\xff")
          if !(packet =~ /\A\x00(.*)\xff\z/nm)
            raise(Riddl::WebSocket::Error, "input must start with \\x00 and end with \\xff")
          end
          $1.respond_to?(:force_encoding) ? $1.force_encoding('UTF-8') : $1
        else
          nil
        end
      elsif version >= 7 
        b1 = BinData::Uint8be.read(io); raise(Riddl::WebSocket::Error, 'strange frame format b1') if b1.nil?
        b2 = BinData::Uint8be.read(io); raise(Riddl::WebSocket::Error, 'strange frame format b2') if b2.nil?

        opcode = b1 & 0x0f
        has_mask = (b2 & 0x80) >> 7
        len = b2 & 0x7f
        if len == 126
          len = BinData::Uint16be.read(io)
        elsif len == 127  
          len = BinData::Uint64be.read(io)
        end

        mask_key = io.read(has_mask * 4)

        ret = ''
        if has_mask == 1
          dat = io.read(len)
          cnt = 0
          dat.each_byte do |b|
            ret << (b ^ mask_key[cnt % mask_key.length])
            cnt += 1
          end
        else  
          ret = io.read(len)
          raise Riddl::WebSocket::Error, "unmasked frame: #{ret}"
        end  

        ret
      end  
    end

  end
end
