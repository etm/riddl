gem 'em-websocket', '>= 0.4.0'
require 'em-websocket'
require 'thin'

module Thin #{{{
  class Connection
    attr_accessor :websocket
    def websocket?
      !self.websocket.nil?
    end

    def pre_process_with_websocket
      @request.env['thin.connection'] = self
      pre_process_without_websocket
    end
    alias :pre_process_without_websocket :pre_process
    alias :pre_process :pre_process_with_websocket

    def receive_data_with_websocket(data)
      if self.websocket?
        self.websocket.receive_data(data)
      else
        receive_data_without_websocket(data)
      end
    end
    alias :receive_data_without_websocket :receive_data
    alias :receive_data :receive_data_with_websocket

    def unbind_with_websocket
      if self.websocket?
        self.websocket.unbind
      else
        unbind_without_websocket
      end
    end
    alias :unbind_without_websocket :unbind
    alias :unbind :unbind_with_websocket
  end
end   #}}}

module EventMachine
  module WebSocket
    class Handshake
      def receive_data(data)
        @parser = data
        @headers = data.headers
        process(@headers, data.body)
      end
    end
  end  
end  

module Riddl
  module Protocols
    class WebSocket < ::EventMachine::WebSocket::Connection
      class Error < RuntimeError; end

      class ParserData
        attr_accessor :headers, :request_path, :query_string, :http_method, :body, :request_url
        def match(what)
          @body =~ what 
        end
        def upgrade?
          true
        end
      end

      def self.new(*args)
        instance = allocate
        instance.__send__(:initialize, *args)
        instance
      end

      def send_data(*args)
        EM.next_tick do
          @socket.send_data(*args)
        end  
      end

      def close_connection(*args)
        EM.next_tick do
          trigger_on_close
          @socket.close_connection(*args)
        end  
      end

      def trigger_on_message(msg);    @app.onmessage(msg);                        end
      def trigger_on_open(handshake); @closed = false; @app.onopen;               end
      def trigger_on_close;           @closed = true;  @app.onclose;              end
      def trigger_on_error(error);    @closed = true;  @app.onerror(error); true; end

      def initialize(app, socket)
        @app = app
        @socket = socket
        @ssl = socket.backend.respond_to?(:ssl?) && socket.backend.ssl?
        @closed = true
        socket.websocket = self
        socket.comm_inactivity_timeout = 0
      end

      def closed?
        @closed
      end
    end
  end
end
