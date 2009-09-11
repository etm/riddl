module Riddl
  class Implementation
    def initialize(headers,parameters,relative,match,env,args)
      @h = headers                    # incoming riddl headers
      @p = parameters                 # incoming riddl parameters
      @a = args                       # args to run command
      @m = @matching_resource = match # the path of the branch matching, important for recursive
      @r = @relative = relative       # the matching path
      @e = @env = env                 # environment (all headers)

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
