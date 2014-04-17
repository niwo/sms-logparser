module SmsLogparser
  class Parser

    def self.extract_data_from_msg(message)
      data = nil
      if self.match?(message)
        SmsLogparser::Loggster.instance.debug { "Parser MATCH: #{message}" }
        match = message.match /\/content\/(\d+)\/(\d+)\/(\d+)\/(\w+\.\w+)\s.*\"\s\d+\s(\d+).+"(.*)"$/
        if match
          traffic_type = Parser.get_traffic_type(match[6])
          visitor_type = Parser.get_visitor_type(traffic_type, match[4])
          data = {
            :customer_id => match[1],
            :author_id => match[2],
            :project_id => match[3],
            :file =>  match[4],
            :bytes => match[5],
            :user_agent => match[6],
            :traffic_type => traffic_type,
            :visitor_type => visitor_type
          }
        end
      else
        SmsLogparser::Loggster.instance.debug { "Parser IGNORE: #{message}" }
      end
      return data unless block_given?
      yield data
    end

    def self.match?(message)
      match = message.match(/\/content\/.+\/(\S+) .+ (200|206)/i)
      # ignore detect.mp4 and index.m3u8 
      if match
        return true unless match[1] =~ /detect.mp4|index.m3u8/i
      end
      false
    end

    # see https://developer.mozilla.org/en-US/docs/Browser_detection_using_the_user_agent
    # for mobile browser detection
    def self.get_traffic_type(user_agent)
      case user_agent
      when /.*(iTunes).*/i
        'TRAFFIC_PODCAST'
      when /.*(Mobi|IEMobile|Mobile Safari|iPhone|iPod|iPad|Android|BlackBerry|Opera Mini).*/
        'TRAFFIC_MOBILE'
      else
        'TRAFFIC_WEBCAST'
      end
    end

    def self.get_visitor_type(traffic_type, file)
      return 'VISITORS_MOBILE' if File.extname(file) == '.m3u8'
      case traffic_type
      when 'TRAFFIC_PODCAST'
        'VISITORS_PODCAST'
      when 'TRAFFIC_MOBILE'
        File.extname(file) != '.ts' ? 'VISITORS_MOBILE' : nil
      else
        'VISITORS_WEBCAST'
      end
    end

  end # class
end # module