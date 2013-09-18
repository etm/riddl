require File.expand_path(File.dirname(__FILE__) + '/smartrunner.rb')
require File.expand_path(File.dirname(__FILE__) + '/../lib/ruby/riddl/client')
require 'xml/smart'
require 'pp'

class TestDecHy <  MiniTest::Unit::TestCase
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
  NORUN = false

  def test_dechy
    ep = Riddl::Client.interface(SERVER[1].url,SERVER[1].schema)

    test = ep.resource('/')
    status, res = test.get
    assert status == 200
    doc = XML::Smart.string(res[0].value.read)
    assert doc.find('/processing-instruction("xml-stylesheet")').length == 1
    assert doc.find('/processing-instruction("xml-stylesheet")').first.content =~ /instances\.xsl/
    assert doc.find('/instances/instance').length == 2

    test = ep.resource('/1')
    status, res = test.get
    assert status == 200
    doc = XML::Smart.string(res[0].value.read)
    assert doc.find('/processing-instruction("xml-stylesheet")').length == 1
    assert doc.find('/processing-instruction("xml-stylesheet")').first.content =~ /info\.xsl/
    assert doc.find('/info/properties').length == 1

    test = ep.resource('/1/properties')
    status, res = test.get
    assert status == 200
    doc = XML::Smart.string(res[0].value.read)
    assert doc.find('/processing-instruction("xml-stylesheet")').length == 1
    assert doc.find('/processing-instruction("xml-stylesheet")').first.content =~ /properties\.xsl/
    assert doc.find('/xmlns:properties/xmlns:name').length == 1
    assert doc.find('/xmlns:properties/xmlns:state').length == 1
    assert doc.find('/xmlns:properties/xmlns:dataelements').length == 1
    assert doc.find('/xmlns:properties/xmlns:endpoints').length == 1
    assert doc.find('/xmlns:properties/xmlns:handlerwrapper').length == 1
    assert doc.find('/xmlns:properties/xmlns:description').length == 1

    test = ep.resource('/1/properties/values')
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

    test = ep.resource('/1/properties/values/name')
    status, res = test.get
    assert status == 200
    assert res[0].value == 'laller'
  end
end
