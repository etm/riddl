require "socket"

WS_FLASH_SOCKET_POLICY = "<cross-domain-policy><allow-access-from domain='*' to-ports='*'/></cross-domain-policy>\n"

server = TCPServer.open(843)
loop {
  Thread.start(server.accept) do |client|
    client.puts WS_FLASH_SOCKET_POLICY
    client.close
  end
}
