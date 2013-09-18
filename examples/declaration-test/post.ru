require 'rack'
require 'socket'
require '../../lib/ruby/riddl/server'
require '../../lib/ruby/riddl/commonlogger'
require '../../lib/ruby/riddl/utils/erbserve'

require 'pp'

class S < Riddl::Implementation
  def response
    @p << Riddl::Parameter::Simple.new("security","mui secure")
  end
end  

options[:Port] = 9202

run Riddl::Server.new("post.xml") {
  process_out false
  logger Riddl::CommonLogger.new("Post","main.log")
  on resource do
    run S if get '*'
  end
}
