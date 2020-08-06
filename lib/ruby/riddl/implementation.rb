module Riddl
  class Implementation
    def initialize(request)
      @request = request

      @h =     request[:h]     # incoming riddl headers
      @p =     request[:p]     # incoming riddl parameters
      @r =     request[:r]     # the matching resource path (fixed)
      @s =     request[:s]     # the matching resource path schema (fixed)
      @match = request[:match] # the matching resource path schema for current resource, important for recursive
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

  class SSEImplementation
    def initialize(ws)
      @ws    = ws
      @r     = ws[:r]     # the matching resource path
      @s     = ws[:s]     # the matching resource path schema
      @match = ws[:match] # the path of the branch matching, important for recursive
      @env   = ws[:env]   # environment (all headers)
      @a     = ws[:a]     # args to run command
    end

    def onopen;end
    def onclose;end
    def onerror(err);end

    def send(data)
      @ws[:io].send_with_id 'data', data
    end
    def send_with_id(id,data)
      @ws[:io].send_with_id id, data
    end

    def io=(connection)
      @ws[:io] = connection
    end
    def io
      @ws[:io]
    end
    def closed?
      @ws[:io].closed?
    end

    def close
      @ws[:io].close
    end
  end

  class WebSocketImplementation
    def initialize(ws)
      @ws    = ws
      @r     = ws[:r]     # the matching resource path
      @s     = ws[:s]     # the matching resource path schema
      @match = ws[:match] # the path of the branch matching, important for recursive
      @env   = ws[:env]   # environment (all headers)
      @a     = ws[:a]     # args to run command
    end

    def onopen;end
    def onclose;end
    def onmessage;end
    def onerror(err);end

    def send(data)
      @ws[:io].send data
    end

    def io=(connection)
      @ws[:io] = connection
    end
    def io
      @ws[:io]
    end
    def closed?
      @ws[:io].closed?
    end

    def close
      @ws[:io].close_connection
    end
  end
end
