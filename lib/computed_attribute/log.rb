require 'logger'

module ComputedAttribute
  class Log
    class << self
      def logger
        return @logger if @logger.present?
        @logger = Logger.new(STDOUT)
        @logger.level =
          case ENV['CA_LOG_LEVEL']
          when 'warn' then Logger::WARN
          when 'debug' then Logger::DEBUG
          when 'info' then Logger::INFO
          when 'fatal' then Logger::FATAL
          when 'unknown' then Logger::UNKNOWN
          when 'error' then Logger::ERROR
          end
        @logger
      end

      def log(message)
        return if ENV['CA_LOG_LEVEL'].nil?
        logger.debug(message)
      end
    end
  end
end
