require 'null_logger'

module AsyncCable
  class Config < Anyway::Config
    attr_config logger: NullLogger.new

    def log_level
      logger.level
    end

    def log_level=(val)
      logger.level = val
    end
  end
end
