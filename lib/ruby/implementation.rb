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
end
