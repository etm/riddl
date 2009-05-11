module Riddl
  class Implementation
    def initialize(headers,parameters)
      @h = headers
      @p = parameters
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
