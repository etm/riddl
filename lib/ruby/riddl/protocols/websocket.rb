require 'faye/websocket'
Faye::WebSocket.load_adapter('thin')

module Riddl
  module Protocols
    class WebSocket
      class Error < RuntimeError; end

      def initialize(app, env)
        @app = app
        @closed = true
        @socket = Faye::WebSocket.new(env)

        @socket.on(:open)    { trigger_on_open }
        @socket.on(:message) { |event| trigger_on_message(event.data) }
        @socket.on(:close)   { trigger_on_close }
        @socket.on(:error)   { |event| trigger_on_error(event.message) }
      end

      def dispatch
        @socket.rack_response
      end

      def send(data)
        EM.next_tick { @socket.send(data) unless closed? }
      end

      def close_connection
        EM.next_tick { @socket.close unless closed? }
      end

      def closed?
        @closed
      end

      private

      def trigger_on_open;       @closed = false; @app.onopen;    end
      def trigger_on_message(m); @app.onmessage(m);                end
      def trigger_on_close;      @closed = true;  @app.onclose;    end
      def trigger_on_error(msg); @app.onerror(msg);                end
    end
  end
end
