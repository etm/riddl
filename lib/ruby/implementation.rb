module Riddl
  class Implementation
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
