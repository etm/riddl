require File.expand_path(File.dirname(__FILE__) + '/smartrunner.rb')
require File.expand_path(File.dirname(__FILE__) + '/../lib/ruby/riddl/client')
require 'xml/smart'
require 'pp'

class TestWebsocket <  Minitest::Test
  include ServerCase

  SERVER = [
    TestServerInfo.new(
      File.expand_path(File.dirname(__FILE__) + '/../examples/websocket/server.rb'),
      File.expand_path(File.dirname(__FILE__) + '/../examples/websocket/description.xml')
    )
  ]
  NORUN = false

  def test_websocket
    ep = Riddl::Client.interface(SERVER[0].url,SERVER[0].schema)

    test = ep.resource('/')
    status, res = test.get
    assert status == 200
    assert res.length == 1
    assert res[0].mimetype == 'text/plain'
    assert res[0].value.read == 'hello world'

    test.ws do |conn|
      cbs = []

      conn.on :open do
        ### called on connection
        conn.send "hello world"
        conn.send "done"
      end

      conn.on :error do |e|
        ### called on error
        cbs << "Got error: #{e}"
      end

      conn.on :message do |msg|
        ### called when server responds
        cbs << "<#{msg.data}>"
        if msg.data == "done"
          conn.close
        end
      end

      conn.on :close do
        ### called on disconnect
        cbs << "gone"
        EM::stop_event_loop

        assert cbs.length == 4
        assert cbs[0] == '<oasch 1>'
        assert cbs[1] == '<hello world>'
        assert cbs[2] == '<done>'
        assert cbs[3] == 'gone'
      end
    end

  end
end
