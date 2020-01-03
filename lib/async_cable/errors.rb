module AsyncCable
  module Errors
    class Error < StandardError
      def code
        1999
      end
    end

    # @see AsyncCable::Connection#handle_open
    class StreamNameNotSet < Error
      def initialize(class_name)
        super("#stream_for must be called with stream name in #{class_name}#on_open")
      end
    end

    # @see AsyncCable::Connection#reject_unauthorized
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
