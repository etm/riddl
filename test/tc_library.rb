require File.expand_path(File.dirname(__FILE__) + '/smartrunner.rb')
require File.expand_path(File.dirname(__FILE__) + '/../lib/ruby/riddl/client')
require 'xml/smart'
require 'pp'

class TestLibrary <  MiniTest::Unit::TestCase
  include ServerCase

  SERVER = [
    TestServerInfo.new(
      File.expand_path(File.dirname(__FILE__) + '/../examples/library/server.rb'),
      File.expand_path(File.dirname(__FILE__) + '/../examples/library/description.xml')
    )
  ]
  NORUN = false

  def test_library
    ep = Riddl::Client.interface(SERVER[0].url,SERVER[0].schema)

    test = ep.resource('/')
    status, res = test.get
    assert status == 200
    assert res.length == 1
    assert res[0].mimetype == 'text/plain'


    test = ep.resource('/books')
    status, res = test.request 'get' => [
      Riddl::Header.new("Library",7),
      Riddl::Parameter::Simple.new("author","Mangler"),
      Riddl::Parameter::Simple.new("title","12 bottles of beer on the wall")
    ]
    assert status == 200
    assert res.length == 1
    assert res[0].mimetype == 'text/xml'

    doc = XML::Smart.string(res[0].value.read)
    assert doc.find('string(/books/book/title)') == '12 bottles of beer on the wall'
    assert doc.find('string(/books/book/author[1])') == 'Agador'
    assert doc.find('string(/books/book/author[2])') == 'Mangler'
  end
end
