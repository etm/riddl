require File.expand_path(File.dirname(__FILE__) + '/smartrunner.rb')
require File.expand_path(File.dirname(__FILE__) + '/../lib/riddl/client')
require 'xml/smart'
require 'pp'

class TestDecLo <  MiniTest::Unit::TestCase
  include ServerCase

  SERVER = [
    TestServerInfo.new(
      File.expand_path(File.dirname(__FILE__) + '/../examples/declaration-server-local/declaration.rb'),
      File.expand_path(File.dirname(__FILE__) + '/../examples/declaration-server-local/declaration.xml')
    )
  ]
  NORUN = false

  def test_declo
    ep = Riddl::Client.interface(SERVER[0].url,SERVER[0].schema)

    test = ep.resource('/')
    status, res = test.get
    assert status == 200
    doc = XML::Smart.string(res[0].value.read)
    assert doc.find('/processing-instruction("xml-stylesheet")').length == 1
    assert doc.find('/processing-instruction("xml-stylesheet")').first.content =~ /properties\.xsl/
    assert doc.find('/xmlns:properties/xmlns:dataelements/*').length == 2

    test = ep.resource('/values')
    status, res = test.get
    assert status == 200
    doc = XML::Smart.string(res[0].value.read)
    assert doc.find('/processing-instruction("xml-stylesheet")').length == 1
    assert doc.find('/processing-instruction("xml-stylesheet")').first.content =~ /values\.xsl/
    assert doc.find('/xmlns:properties/xmlns:property[.="name"]').length == 1
    assert doc.find('/xmlns:properties/xmlns:property[.="state"]').length == 1
    assert doc.find('/xmlns:properties/xmlns:property[.="dataelements"]').length == 1
    assert doc.find('/xmlns:properties/xmlns:property[.="endpoints"]').length == 1
    assert doc.find('/xmlns:properties/xmlns:property[.="handlerwrapper"]').length == 1
    assert doc.find('/xmlns:properties/xmlns:property[.="description"]').length == 1

    test = ep.resource('/values/state')
    status, res = test.get
    assert status == 200
    assert res[0].value == 'stopped'
  end
end
