module Riddl
  class Implementation
    def initialize(headers,parameters,relative)
      @h = @headers = headers
      @p = @parameters = parameters
      @r = @relative = relative
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
