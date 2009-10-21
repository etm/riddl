require 'rack'
require 'socket'
require '../../lib/ruby/server'
require '../../lib/ruby/commonlogger'
require '../../lib/ruby/utils/erbserve'

require 'pp'

class S < Riddl::Implementation
  def response
    @p.delete_if{|e| e.name == "security"}
    @p
  end
end  
class M < Riddl::Implementation
  def response
    Riddl::Parameter::Simple.new("c",@m[0].value)
  end
end  

options[:Port] = 9200

run Riddl::Server.new("pre.xml") {
  process_out false
  logger Riddl::CommonLogger.new("Pre","main.log")
  on resource do
    run M if get 'm'
    run S if get '*'
  end
}
