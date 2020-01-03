require 'async_cable/version'
require 'async_cable/errors'
require 'async_cable/config'
require 'async_cable/registry'
require 'async_cable/connection'
require 'async_cable/server'

module AsyncCable

  # @return [Async::Config]
  def config
    @config ||= Config.new
  end

  # @yield [Async::Config]
  def configure
    yield config
  end

  # Transmit data to all WS connections.
  # @param data [Hash]
  def broadcast(data)
    config.logger.debug { "#{name}.broadcast data=#{data.inspect}" }
    Registry.each { |conn| conn.transmit(data) }
  end

  module_function :configure, :config, :broadcast
  config # initialize config right away to prevent racing.
end
