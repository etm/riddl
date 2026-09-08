module Riddl
  module Protocols
    module SSE
      class Error < RuntimeError; end

      class ParserData
        attr_accessor :headers, :request_path, :query_string, :http_method, :body, :request_url
      end

      class Base #{{{
        def initialize(app, env)
          @app = app
          @env = env
          @closed = true
        end

        def send_with_id(id, data)
          return if closed?
          push("#{id}: #{data}" + EOL + EOL)
        end

        def close
          return if closed?
          @closed = true
          do_close
        end

        def closed?
          @closed
        end

        def trigger_on_open;  @closed = false; res = @app.onopen; res ? true : false; end
        def trigger_on_close; @closed = true;  @app.onclose;                          end

        def response_headers(cross_site_xhr)
          headers = {
            'Content-Type' => 'text/event-stream',
            'Cache-Control' => 'no-cache',
            'X-Accel-Buffering' => 'no'
          }
          if @env['HTTP_ORIGIN'] && cross_site_xhr
            headers['Access-Control-Allow-Origin'] = '*'
            headers['Access-Control-Max-Age'] = '0'
          end
          headers
        end
        protected :response_headers
      end #}}}

      class Thin < Base #{{{
        class DeferrableBody #{{{
          include EventMachine::Deferrable

          def call(body)
            body.each { |chunk| @body_callback.call(chunk) }
          end

          def each(&blk)
            @body_callback = blk
          end
        end #}}}

        def initialize(app, env)
          super
          @env['async.close'].callback { trigger_on_close }
          @body = DeferrableBody.new
        end

        def dispatch(data, cross_site_xhr)
          headers = response_headers(cross_site_xhr)
          EventMachine::next_tick {
            if trigger_on_open
              @env['async.callback'].call [200, headers, @body]
            else
              @body.fail
              @env['async.callback'].call [404, headers, {}]
            end
          }
          nil
        end

        def push(str)
          EM.next_tick { @body.call [str] }
        end
        protected :push

        def do_close
          EM.next_tick { @body.succeed }
        end
        protected :do_close
      end #}}}

      class Generic < Base # other servers like PUMA
        class QueueBody #{{{
          def initialize
            @queue = Queue.new
            @on_close = nil
            @closed_fired = false
          end

          def on_close(&blk)
            @on_close = blk
          end

          def call(chunk)
            Array(chunk).each { |c| @queue << chunk_encode(c) }
          end

          def each
            loop do
              chunk = @queue.pop
              break if chunk.nil?
              begin
                yield chunk
              rescue IOError, Errno::EPIPE, Errno::ECONNRESET
                break
              end
            end
          ensure
            fire_on_close
          end

          def close
            @queue << "0#{EOL}#{EOL}"
            @queue << nil
          end

          def chunk_encode(c)
            c.bytesize.to_s(16) + EOL + c + EOL
          end
          private :chunk_encode

          def fire_on_close
            return if @closed_fired
            @closed_fired = true
            @on_close.call if @on_close
          end
          private :fire_on_close
        end #}}}

        def initialize(app, env)
          super
          @body = QueueBody.new
          @body.on_close { trigger_on_close }
        end

        def dispatch(data, cross_site_xhr)
          headers = response_headers(cross_site_xhr).merge('Transfer-Encoding' => 'chunked')
          if trigger_on_open
            [200, headers, @body]
          else
            @body.close
            [404, headers, []]
          end
        end

        def push(str)
          @body.call [str]
        end
        protected :push

        def do_close
          @body.close
        end
        protected :do_close
      end
    end
  end
end
