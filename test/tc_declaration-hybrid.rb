require File.expand_path(File.dirname(__FILE__) + '/smartrunner.rb')
require File.expand_path(File.dirname(__FILE__) + '/../lib/riddl/client')
require 'xml/smart'

class TestProd <  MiniTest::Unit::TestCase
  include ServerCase

  SERVER = [
    TestServerInfo.new(
      File.expand_path(File.dirname(__FILE__) + '/../examples/declaration-server-hybrid/xsloverlay.rb'),
      File.expand_path(File.dirname(__FILE__) + '/../examples/declaration-server-hybrid/xsloverlay.xml')
    ),
    TestServerInfo.new(
      File.expand_path(File.dirname(__FILE__) + '/../examples/declaration-server-hybrid/declaration.rb'),
      File.expand_path(File.dirname(__FILE__) + '/../examples/declaration-server-hybrid/declaration.xml')
    )
  ]
  NORUN = true

  def test_producer
    ep = Riddl::Client.interface(SERVER[1].url,SERVER[1].schema)
  end
end
