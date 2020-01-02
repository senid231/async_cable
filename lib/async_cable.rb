require 'async_cable/version'
require 'async_cable/errors'
require 'async_cable/config'
require 'async_cable/registry'
require 'async_cable/connection'
require 'async_cable/server'

module AsyncCable
  def config
    @config ||= Config.new
  end

  def configure
    yield config
  end

  def broadcast(data)
    config.logger.debug { "#{name}.broadcast data=#{data.inspect}" }
    Registry.find.each { |conn| conn.transmit(data) }
  end

  module_function :configure, :config, :broadcast
  config # initialize config right away to prevent racing.
end
