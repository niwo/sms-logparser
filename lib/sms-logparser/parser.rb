module SmsLogparser
  module Parser

    module_function

    def logger
      SmsLogparser::Loggster.instance
    end

    def extract_data_from_msg(message)
      data = []
      if LogMessage.match?(message)
        logger.debug { "Parser MATCH: #{message}" }
        log_message = LogMessage.new(message)
        if log_message.match
          data << Parser.extract_usage_data(log_message)
          data << Parser.extract_visit(log_message)
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
      log_message.account_info.merge(
        type: "TRAFFIC_#{log_message.type}",
        value: log_message.bytes
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

  end # class
end # module