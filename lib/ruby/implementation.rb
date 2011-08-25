module Riddl
  class Implementation
    def initialize(request)
      @request = request

      @h =     request[:h]     # incoming riddl headers
      @p =     request[:p]     # incoming riddl parameters
      @r =     request[:r]     # the matching path
      @match = request[:match] # the path of the branch matching, important for recursive
      @env =   request[:env]   # environment (all headers)
      @a =     request[:a]     # args to run command
      @m =     request[:m]     # get, put, post, ...

      @headers = []
    end
    def response                      # riddl parameters to return
      @response || []
    end
    def headers                       # riddl headers to return (additional headers not defined in description are okay too)
      @headers
    end
    def status                        # return status
      @status || 200
    end
  end

  class WebSocketImplementation
    def initialize(ws)
      @ws = ws

      @r =     ws[:r]     # the matching path
      @match = ws[:match] # the path of the branch matching, important for recursive
      @env =   ws[:env]   # environment (all headers)
      @a =     ws[:a]     # args to run command
    end

    def closed?
      @ws[:io].closed?
    end

    def onopen;end
    def onclose;end
    def on;end

    def send(data)
      str = data.dup
      data = data.respond_to?(:force_encoding) ? data.dup.force_encoding("ASCII-8BIT") : data
      @ws[:io].write("\x00#{data}\xff")
      @ws[:io].flush
    end

    # def encode_hybi(buf, opcode, base64=False):
    #   """ Encode a HyBi style WebSocket frame.
    #   Optional opcode:
    #   0x0 - continuation
    #   0x1 - text frame (base64 encode buf)
    #   0x2 - binary frame (use raw buf)
    #   0x8 - connection close
    #   0x9 - ping
    #   0xA - pong
    #   """
    #   if base64:
    #       buf = b64encode(buf)

    #   b1 = 0x80 | (opcode & 0x0f) # FIN + opcode
    #   payload_len = len(buf)
    #   if payload_len <= 125:
    #       header = struct.pack('>BB', b1, payload_len)
    #   elif payload_len > 125 and payload_len <= 65536:
    #       header = struct.pack('>BBH', b1, 126, payload_len)
    #   elif payload_len >= 65536:
    #       header = struct.pack('>BBQ', b1, 127, payload_len)

    #   #print("Encoded: %s" % repr(header + buf))

    #   return header + buf, len(header), 0

  end
end
