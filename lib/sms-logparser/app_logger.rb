module SmsLogparser
  require 'logger'
  require 'singleton'

  class AppLogger < Logger
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

  end
end