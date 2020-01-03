require 'async/websocket'
require 'async/websocket/adapters/rack'

module AsyncCable
  class Server
    # Rack application should be used inside Async::Reactor loop.

    attr_reader :connection_class

    # @param connection_class [Class] subclass of AsyncCable::Connection.
    # @param block [Proc<Hash>] yields when not valid WS request.
    # @yieldreturn [Array] `[status,headers,body]`
    def initialize(connection_class:, &block)
      @connection_class = connection_class
      @block = block
    end

    # @param env [Hash]
    # @return [Array] `[status,headers,body]`
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
      # response[1] ca be Protocol::HTTP::Headers::Merged here.
      # We transform it to hash because we don't want to break other middleware logic.
      response[1] = response[1].to_a.to_h if !response.nil? && !response[1].is_a?(Hash)
      response || [400, { 'Content-Type' => 'text/plain' }, ['Not valid ws']]
    end

    def logger
      AsyncCable.config.logger
    end
  end
end
