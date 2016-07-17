module Omnivore
  module Utils
    module Logger

      # @return [Logger] application logger instance
      def logger
        Omnivore.logger
      end

      # Log a debug message
      #
      # @param m [String]
      def debug(m : String)
        logger.debug "[#{self}] - #{m}"
      end

      # Log an info message
      #
      # @param m [String]
      def info(m : String)
        logger.info "[#{self}] - #{m}"
      end

      # Log a warn message
      #
      # @param m [String]
      def warn(m : String)
        logger.warn "[#{self}] - #{m}"
      end

      # Log an error message
      #
      # @param m [String]
      def error(m : String)
        logger.error "[#{self}] - #{m}"
      end

      # Log a fatal message
      #
      # @param m [String]
      def fatal(m : String)
        logger.fatal "[#{self}] - #{m}"
      end

    end
  end
end
