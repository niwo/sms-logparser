module SmsLogparser
  require 'logger'
  require 'singleton'

  class Loggster < Logger
    include Singleton
    
    def initialize
      @level = INFO
      @logdev = STDOUT
      @progname ||= 'sms-logparser'
      @formatter = proc do |severity, datetime, progname, msg|
        "#{datetime} #{severity} [sms-logparser v#{SmsLogparser::VERSION}] #{msg}\n"
      end
    end

    def set_log_device(log_file_path = nil)
      device = log_file_path ? File.open(log_file_path, "a") : STDOUT
      @logdev = Logger::LogDevice.new(device)
      self
    end

    def set_severity(severity = "info")
      self.sev_threshold = case severity
      when "debug"
        Logger::DEBUG
      when "info"
        Logger::INFO
      when "warn"
        Logger::WARN
      when "error"
        Logger::ERROR
      when "fatal"
        Logger::FATAL
      else 
        Logger::INFO
      end
      self
    end

  end
end