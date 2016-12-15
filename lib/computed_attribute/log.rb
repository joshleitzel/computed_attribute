require 'logger'

module ComputedAttribute
  class Log
    class << self
      def log_level=(level)
        log_level = case level
                    when :warn then Logger::WARN
                    when :debug then Logger::DEBUG
                    when :info then Logger::INFO
                    when :fatal then Logger::FATAL
                    when :unknown then Logger::UNKNOWN
                    when :error then Logger::ERROR
                    end
        @logger = Logger.new(STDOUT)
        @logger.level = log_level || Logger::WARN
      end

      def logger
        return @logger if @logger.present?
        self.log_level = :warn
        @logger
      end

      def log(message)
        logger.debug(message)
      end
    end
  end
end
