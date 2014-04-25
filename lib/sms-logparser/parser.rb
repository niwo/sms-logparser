module SmsLogparser
  class Parser

    def initialize(options = {})
      @options = options
    end

    def logger
      SmsLogparser::Loggster.instance
    end

    def extract_data_from_msg(message)
      data = []
      log_message = LogMessage.new(message, @options)
      if log_message.match?
        logger.debug { "Parser MATCH: #{message}" }
        if log_message.match
          data << extract_usage_data(log_message)
          data << extract_visit(log_message)
          data.compact! # remove nil values
        else
          logger.warn { "Can't extract data from message: #{message}" }
        end
      else
        logger.debug { "Parser IGNORE: #{message}" }
      end
      yield data if block_given?
      data
    end

    def extract_usage_data(log_message)
      traffic = log_message.bytes * traffic_correction_factor(log_message.type)
      log_message.account_info.merge(
        type: "TRAFFIC_#{log_message.type}",
        value: traffic.round(0)
      )
    end

    def extract_visit(log_message)
      # only measure file bigger than 256K
      size_limit = 256 * 1024
      if log_message.status == 200 &&
        log_message.bytes > size_limit &&
        (!log_message.args || log_message.args.match(/position=(0|1)/)) &&
        (log_message.file_extname =~ /\.(mp3|mp4|flv|f4v)/ || log_message.file == 'index.m3u8')
        visit_data = log_message.account_info.merge(
          type: "VISITORS_#{log_message.type}",
          value: 1
        )
        logger.debug { "Counting visit: message=\"#{log_message.message}\" data=#{visit_data}" }
      else
        logger.debug { "NOT counting VISITORS_#{log_message.type} for: #{log_message.message}" }
      end
      visit_data || nil
    end

    def traffic_correction_factor(traffic_type)
      factor = case traffic_type
      when 'WEBCAST'
        @options[:webcast_traffic_correction] || 1.0
      when 'MOBILE'
        @options[:mobile_traffic_correction] || 1.0
      when 'PODCAST'
        @options[:podcast_traffic_correction] || 1.0
      else
        1.0
      end
      factor.to_f
    end

  end # class
end # module