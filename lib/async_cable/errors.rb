module AsyncCable
  module Errors
    class Error < StandardError
      def code
        1999
      end
    end

    class StreamNameNotSet < Error
      def initialize(class_name)
        super("#stream_for must be called with stream name in #{class_name}#on_open")
      end
    end

    class UnauthorizedError < Error
      def initialize(reason = nil)
        super(reason || 'unauthorized')
      end

      def code
        1401
      end
    end
  end
end
