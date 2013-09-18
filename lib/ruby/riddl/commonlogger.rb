require 'logger'

module Riddl

  class CommonLogger
    def initialize(appname="Riddl Server",logger=$stdout)
      @logger = Logger.new(logger)
      @appname = appname
    end

    def write(it)
      @logger << @appname + ': ' + it
    end
  end

end
