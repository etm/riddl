require File.expand_path(File.dirname(__FILE__) + '/smartrunner.rb')
require File.expand_path(File.dirname(__FILE__) + '/../lib/riddl/client')
require 'xml/smart'

class TestProd <  MiniTest::Unit::TestCase
  include ServerCase

  SERVER = [
    TestServerInfo.new(
      File.expand_path(File.dirname(__FILE__) + '/../examples/notifications/producer.rb'),
      File.expand_path(File.dirname(__FILE__) + '/../examples/notifications/producer.declaration.xml')
    )
  ]
  NORUN = false

  def test_producer
    nots = Riddl::Client.interface(SERVER[0].url,SERVER[0].schema)

    test = nots.resource("/notifications/subscriptions")
    status, res = test.post [
      Riddl::Parameter::Simple.new("url","http://test.org"),
      Riddl::Parameter::Simple.new("topic","/oliver"),
      Riddl::Parameter::Simple.new("events","get"),
      Riddl::Parameter::Simple.new("topic","/juergen"),
      Riddl::Parameter::Simple.new("events","praise,adore")
    ]
    assert status == 200
    assert (key = res[0].value).is_a?(String)

    status, res = test.get

    doc = XML::Smart.string(res[0].value.read)
    doc.register_namespace 'n', 'http://riddl.org/ns/common-patterns/notifications-producer/1.0'
    assert doc.find("/n:subscriptions/n:subscription[@id='#{key}' and @url='http://test.org']").any?

    test = nots.resource("/notifications/subscriptions/#{key}")
    status, res = test.get
    assert status == 200

    doc = XML::Smart.string(res[0].value.read)
    doc.register_namespace 'n', 'http://riddl.org/ns/common-patterns/notifications-producer/1.0'

    assert doc.find('/n:subscription/n:topic').length == 2
    assert doc.find('/n:subscription/n:topic[1]/n:event').length == 1
    assert doc.find('/n:subscription/n:topic[2]/n:event').length == 2

    status, res = test.delete
    assert status == 200

    test = nots.resource("/notifications/subscriptions/#{key}")
    status, res = test.get
    assert status == 500
  end
end
