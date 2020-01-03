require 'singleton'
require 'forwardable'

module AsyncCable
  class Registry
    include Singleton
    extend SingleForwardable
    @mutex = Mutex.new

    single_delegate [:add, :remove, :find, :all] => :instance

    # Adds connection to registry.
    # @param channel_name [String]
    # @param stream_name [String]
    # @param connection [AsyncCable::Connection]
    def add(channel_name, stream_name, connection)
      @mutex.synchronize do
        subscribers[channel_name][stream_name].push(connection)
        connection
      end
    end

    # Removes connection from registry.
    # @param channel_name [String]
    # @param stream_name [String]
    # @param connection [AsyncCable::Connection]
    def remove(channel_name, stream_name, connection)
      @mutex.synchronize do
        subscribers[channel_name][stream_name].delete(connection)
        subscribers[channel_name].delete(stream_name) if subscribers[channel_name][stream_name].empty?
        connection
      end
    end

    # Return all connections from all channels when `channel_name` omitted.
    # Return all connections from channel when `stream_name` omitted.
    # Return connections from channel stream when `channel_name` and `stream_name` provided.
    # @param channel_name [String,NilClass]
    # @param stream_name [String,NilClass]
    # @return [Array<AsyncCable::Connection>,Array]
    def find(channel_name = nil, stream_name = nil)
      @mutex.synchronize do
        return subscribers.values.map(&:values).flatten if channel_name.nil?
        return subscribers[channel_name].values.flatten if stream_name.nil?
        subscribers[channel_name][stream_name]
      end
    end

    # Iterate connections asynchronously.
    # @param channel_name [String,NilClass]
    # @param stream_name [String,NilClass]
    # @yield connection [AsyncCable::Connection]
    def each(channel_name = nil, stream_name = nil, &block)
      list = find(channel_name, stream_name)
      Util.each_async(list, &block)
    end

    private

    def subscribers
      @subscribers ||= new_subscribers
    end

    def new_subscribers
      Hash.new do |hash, channel_name|
        hash[channel_name] = Hash.new { |h, stream_name| h[stream_name] = []; h }
        hash
      end
    end
  end
end
