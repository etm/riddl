require File.expand_path(File.dirname(__FILE__) + '/smartrunner.rb')
require File.expand_path(File.dirname(__FILE__) + '/../lib/ruby/riddl/client')
require 'net/http'
require 'timeout'

module SSEScenario
  def test_sse
    info = self.class::SERVER[0]
    ep = Riddl::Client.interface(info.url, info.schema)

    test = ep.resource('/')
    status, res = test.get
    assert status == 200
    assert res.length == 1
    assert res[0].mimetype == 'text/plain'
    assert res[0].value.read == 'hello world'

    uri = URI(info.url)
    events = Queue.new
    opened = Queue.new

    reader = Thread.new do
      begin
        Net::HTTP.start(uri.host, info.port) do |http|
          req = Net::HTTP::Get.new('/', { 'Accept' => 'text/event-stream' })
          http.request(req) do |response|
            opened << response.code
            buffer = +''
            response.read_body do |chunk|
              buffer << chunk
              while (idx = buffer.index("\r\n\r\n"))
                events << buffer.slice!(0..idx + 3)
              end
            end
          end
        end
      rescue IOError, Errno::ECONNRESET
        # expected once the reader thread is killed below
      end
    end

    assert Timeout.timeout(5) { opened.pop } == '200'

    # a plain GET on the same server broadcasts to every open SSE connection
    # (examples/sse/server.rb's Bar#response) -- deterministic, no need to
    # wait on the 15s heartbeat from the `parallel` block.
    status, _res = test.get
    assert status == 200

    event = Timeout.timeout(5) { events.pop }
    assert event == "data: some data\r\n\r\n"

    reader.kill
    reader.join
  end
end

class TestSSEThin < Minitest::Test
  include ServerCase
  include SSEScenario

  SERVER = [
    TestServerInfo.new(
      File.expand_path(File.dirname(__FILE__) + '/../examples/sse/server.rb') + ' -o server=thin',
      File.expand_path(File.dirname(__FILE__) + '/../examples/sse/description.xml')
    )
  ]
  NORUN = false
end

class TestSSEPuma < Minitest::Test
  include ServerCase
  include SSEScenario

  SERVER = [
    TestServerInfo.new(
      File.expand_path(File.dirname(__FILE__) + '/../examples/sse/server.rb') + ' -o server=puma',
      File.expand_path(File.dirname(__FILE__) + '/../examples/sse/description.xml')
    )
  ]
  NORUN = false
end
