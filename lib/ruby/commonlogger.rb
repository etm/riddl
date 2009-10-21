require 'logger'

module Riddl

  class CommonLogger
    def initialize(appname="Riddl Server",logger=$stdout)
      @logger = Logger.new(logger)
      @appname = appname
    end

    # By default, log to rack.errors.
    def info(env,res,time,str='')
      length = 0

      now = Time.now

      @logger << %{%s: %s - %s [%s] "%s %s%s %s" %d %s %0.4f %s\n} %
        [
          @appname, 
          env['HTTP_X_FORWARDED_FOR'] || env["REMOTE_ADDR"] || "-",
          env["REMOTE_USER"] || "-",
          now.strftime("%d/%b/%Y %H:%M:%S"),
          env["REQUEST_METHOD"],
          env["PATH_INFO"],
          env["QUERY_STRING"].empty? ? "" : "?"+env["QUERY_STRING"],
          env["HTTP_VERSION"],
          res.status.to_s[0..3],
          (length.zero? ? "-" : length.to_s),
          now - time,
          str
        ]
    end
  end
end
