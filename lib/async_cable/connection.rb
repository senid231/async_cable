require 'async/websocket/connection'
require 'protocol/websocket/error'

module AsyncCable
  class Connection < Async::WebSocket::Connection

    class_attribute :channel_name, instance_writer: false

    class << self
      def inherited(subclass)
        subclass.channel_name = subclass.name.demodulize.underscore
      end

      def identified_as(channel)
        self.channel_name = channel.to_s
      end

      def logger
        AsyncCable.config.logger
      end

      # Transmit data to all WS connections in current channel and provided stream.
      # @param data [Hash]
      def broadcast(stream_name, data)
        logger.debug { "#{name}.broadcast data=#{data.inspect}" }

        Registry.find(channel_name, stream_name).each do |conn|
          conn.transmit(data) unless conn.closed?
        end
      end
    end

    attr_reader :request
    attr_writer :close_code
    attr_accessor :close_reason

    def initialize(*args, &block)
      super
      @mutex = Mutex.new
    end

    # Will be executed when WS connection opened.
    # #stream_for must be called here with stream name
    def on_open
    end

    # Will be executed when data received from WS client.
    # @param data [Hash]
    def on_data(data)
    end

    # Will be executed when WS connection closed.
    # see #close_code, #close_reason for details.
    def on_close
    end

    # call this method to transmit data to current WS client
    def transmit(data)
      logger.debug { "AsyncCable::Connection#send_command identifier=#{identifier} data=#{data.inspect}" }

      @mutex.synchronize do
        write(data)
        flush
      end
    end

    # @param stream_name [String]
    def stream_for(stream_name)
      @stream_name = stream_name
    end

    # @return [String] stream name
    def stream_name
      @stream_name
    end

    def reject_unauthorized(reason = nil)
      raise UnauthorizedError, reason
    end

    # WS connection close code
    # 1000 - clean close
    # @return [Integer]
    def close_code
      @close_code || Protocol::WebSocket::Error::NO_ERROR
    end

    # Was WS connection closed clean or dirty.
    # @return [Boolean]
    def close_clean?
      close_code == Protocol::WebSocket::Error::NO_ERROR
    end

    # @param env [Hash]
    # @raise [AsyncCable::Errors::StreamNameNotSet] if #stream_for was not called
    # @raise [AsyncCable::Errors::UnauthorizedError] if #reject_unauthorized was called
    def handle_open(env)
      logger.debug { "#{self.class}#handle_open" }
      @request = Rack::Request.new(env)
      on_open
      raise Errors::StreamNameNotSet, self.class.name unless defined?(@stream_name)
      Registry.add(channel_name, stream_name, self)
    end

    def handle_close
      logger.debug { "#{self.class}#handle_close clean=#{close_clean?} code=#{close_code} reason=#{close_reason}" }
      close
      Registry.remove(channel_name, stream_name, self)
      on_close
    end

    def logger
      self.class.logger
    end
  end
end
