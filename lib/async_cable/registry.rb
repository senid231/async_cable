require 'singleton'
require 'forwardable'

module AsyncCable
  class Registry
    include Singleton
    extend SingleForwardable
    @mutex = Mutex.new

    single_delegate [:add, :remove, :find, :all] => :instance

    # @param channel_name [String]
    # @param stream_name [String]
    # @param connection [AsyncCable::Connection]
    def add(channel_name, stream_name, connection)
      @mutex.synchronize do
        subscribers[channel_name][stream_name].push(connection)
        connection
      end
    end

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

    # @param channel_name [String]
    # @param stream_name [String,NilClass]
    def find(channel_name, stream_name = nil)
      @mutex.synchronize do
        return subscribers[channel_name].values.flatten if stream_name.nil?
        subscribers[channel_name][stream_name]
      end
    end

    def all
      @mutex.synchronize do
        subscribers
      end
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
