module Riddl
  class Implementation
    def initialize(headers,parameters,relative,match,env,args)
      @h = @headers = headers
      @m = @matching_resource = match
      @p = @parameters = parameters
      @r = @relative = relative
      @e = @env = env
      @a = @args = args
    end
    def response
      @response || []
    end
    def headers
      @headers || []
    end
    def status
      @status || 200
    end
  end
end
