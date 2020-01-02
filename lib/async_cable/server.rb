require 'async/websocket'
require 'async/websocket/adapters/rack'

module AsyncCable
  class Server
    attr_reader :connection_class

    def initialize(connection_class:)
      @connection_class = connection_class
    end

    def call(env)
      response = Async::WebSocket::Adapters::Rack.open(env, handler: connection_class) do |connection|
        connection.handle_open(env)

        while (data = connection.read)
          connection.on_data(data)
        end
      rescue Protocol::WebSocket::ProtocolError => error
        logger.debug { "#{self.class}#call rescue #{error.class} message=#{error.message} code=#{error.code}" }
        connection.close_code = error.code
        connection.close_reason = error.message
      rescue AsyncCable::Connection::Error => error
        connection.close_code = error.code
        connection.close_reason = error.message
      ensure
        logger.debug { "#{self.class}#call connection closed" }
        connection.handle_close
      end
      response[1] = response[1].to_a.to_h unless response.nil?
      response || [400, { 'Content-Type' => 'text/plain' }, ['Not valid ws']]
    end

    private

    def logger
      AsyncCable.config.logger
    end
  end
end
