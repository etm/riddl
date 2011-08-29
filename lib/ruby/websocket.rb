require 'base64'
require 'digest/sha1'
require 'bindata'

module Riddl
  module WebSocket
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
      p 'nuller'
      if packet = io.gets("\xff")
        return nil if (packet == "\xff")
        if !(packet =~ /\A\x00(.*)\xff\z/nm)
          raise(Riddl::WebSocketError, "input must start with \\x00 and end with \\xff")
        end
        $1.respond_to?(:force_encoding) ? $1.force_encoding('UTF-8') : $1
      else
        nil
      end
    end

    # def decode_hybi(buf, base64=False):
    #   """ Decode HyBi style WebSocket packets.
    #   Returns:
    #   {'fin' : 0_or_1,
    #   'opcode' : number,
    #   'mask' : 32_bit_number,
    #   'hlen' : header_bytes_number,
    #   'length' : payload_bytes_number,
    #   'payload' : decoded_buffer,
    #   'left' : bytes_left_number,
    #   'close_code' : number,
    #   'close_reason' : string}
    #   """

    #   f = {'fin' : 0,
    #        'opcode' : 0,
    #        'mask' : 0,
    #        'hlen' : 2,
    #        'length' : 0,
    #        'payload' : None,
    #        'left' : 0,
    #        'close_code' : None,
    #        'close_reason' : None}

    #   blen = len(buf)
    #   f['left'] = blen

    #   if blen < f['hlen']:
    #       return f # Incomplete frame header

    #   b1, b2 = struct.unpack_from(">BB", buf)
    #   f['opcode'] = b1 & 0x0f
    #   f['fin'] = (b1 & 0x80) >> 7
    #   has_mask = (b2 & 0x80) >> 7

    #   f['length'] = b2 & 0x7f

    #   if f['length'] == 126:
    #       f['hlen'] = 4
    #       if blen < f['hlen']:
    #           return f # Incomplete frame header
    #       (f['length'],) = struct.unpack_from('>xxH', buf)
    #   elif f['length'] == 127:
    #       f['hlen'] = 10
    #       if blen < f['hlen']:
    #           return f # Incomplete frame header
    #       (f['length'],) = struct.unpack_from('>xxQ', buf)

    #   full_len = f['hlen'] + has_mask * 4 + f['length']

    #   if blen < full_len: # Incomplete frame
    #       return f # Incomplete frame header

    #   # Number of bytes that are part of the next frame(s)
    #   f['left'] = blen - full_len

    #   # Process 1 frame
    #   if has_mask:
    #       # unmask payload
    #       f['mask'] = buf[f['hlen']:f['hlen']+4]
    #       b = c = ''
    #       if f['length'] >= 4:
    #           mask = numpy.frombuffer(buf, dtype=numpy.dtype('<u4'),
    #                   offset=f['hlen'], count=1)
    #           data = numpy.frombuffer(buf, dtype=numpy.dtype('<u4'),
    #                   offset=f['hlen'] + 4, count=int(f['length'] / 4))
    #           #b = numpy.bitwise_xor(data, mask).data
    #           b = numpy.bitwise_xor(data, mask).tostring()

    #       if f['length'] % 4:
    #           print("Partial unmask")
    #           mask = numpy.frombuffer(buf, dtype=numpy.dtype('B'),
    #                   offset=f['hlen'], count=(f['length'] % 4))
    #           data = numpy.frombuffer(buf, dtype=numpy.dtype('B'),
    #                   offset=full_len - (f['length'] % 4),
    #                   count=(f['length'] % 4))
    #           c = numpy.bitwise_xor(data, mask).tostring()
    #       f['payload'] = b + c
    #   else:
    #       print("Unmasked frame: %s" % repr(buf))
    #       f['payload'] = buf[(f['hlen'] + has_mask * 4):full_len]

    #   if base64 and f['opcode'] in [1, 2]:
    #       try:
    #           f['payload'] = b64decode(f['payload'])
    #       except:
    #           print("Exception while b64decoding buffer: %s" %
    #                   repr(buf))
    #           raise

    #   if f['opcode'] == 0x08:
    #       if f['length'] >= 2:
    #           f['close_code'] = struct.unpack_from(">H", f['payload'])
    #       if f['length'] > 3:
    #           f['close_reason'] = f['payload'][2:]

    #   return f


  end
end
