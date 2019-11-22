module Riddl
  module Protocols
    class SSE
      class Error < RuntimeError; end

      class ParserData
        attr_accessor :headers, :request_path, :query_string, :http_method, :body, :request_url
      end

      class DeferrableBody
				include EventMachine::Deferrable

				def call(body)
					body.each do |chunk|
						@body_callback.call(chunk)
					end
				end

				def each(&blk)
					@body_callback = blk
				end
			end

      def send_with_id(id, data)
        EM.next_tick do
          @body.call [ "#{id}: #{data}" + EOL + EOL ]
        end
      end

      def close
        EM.next_tick do
          @body.succeed
        end
      end

      def trigger_on_open();          @closed = false; @app.onopen;               end
      def trigger_on_close;           @closed = true;  @app.onclose;              end

      def initialize(app, env)
        @app = app
        @env = env
        @env['async.close'].callback { trigger_on_close }
				@body = DeferrableBody.new
        @closed = true
      end


      def dispatch(data,cross_site_xhr)
        headers = {
          'Content-Type' => 'text/event-stream',
          'Cache-Control' => 'no-cache',
          'X-Accel-Buffering' => 'no'
        }
        if @env['HTTP_ORIGIN'] && cross_site_xhr
          headers['Access-Control-Allow-Origin'] = '*'
          headers['Access-Control-Max-Age'] = '0'
        end
				EventMachine::next_tick {
					@env['async.callback'].call [200, headers, @body]
          trigger_on_open
				}
      end

      def closed?
        @closed
      end
    end
  end
end
