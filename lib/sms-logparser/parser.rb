module SmsLogparser
  class Parser

    def initialize(options = {})
      @options = options
      @logger = SmsLogparser::Loggster.instance
    end

    def extract_data_from_msg(message)
      data = []
      if Parser.match?(message)
        @logger.debug { "Parser MATCH: #{message}" }
        log_message = LogMessage.new(message)
        type = Parser.get_type(log_message.user_agent)
        data << log_message.account_info.merge(
          type: "TRAFFIC_#{type}",
          value: (log_message.bytes * traffic_correction_factor(type)).round(0)
        )
        if log_message.status == 200 &&
          (log_message.file_extname =~ /\.(mp3|mp4|flv|f4v)/ ||
           log_message.file == 'index.m3u8')
          data << log_message.account_info.merge(
            type: "VISITORS_#{type}",
            value: 1,
          )
        end
      else
        @logger.debug { "Parser IGNORE: #{message}" }
      end
      return data unless block_given?
      yield data
    end

    def self.match?(message)
      match = message.match(/\/content\/.+\/(\S+) .+ (200|206)/i)
      # ignore detect.mp4 
      if match
        return true unless match[1] =~ /detect.mp4/i
      end
      false
    end

    # see https://developer.mozilla.org/en-US/docs/Browser_detection_using_the_user_agent
    # for mobile browser detection
    def self.get_type(user_agent)
      case user_agent
      when /.*(iTunes).*/i
        'PODCAST'
      when /.*(Mobi|IEMobile|Mobile Safari|iPhone|iPod|iPad|Android|BlackBerry|Opera Mini).*/
        'MOBILE'
      else
        'WEBCAST'
      end
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