module SmsLogparser
  class LogMessage

    attr_reader :message
    
    def initialize(message)
      # reove double slashes from message
      @message = message.squeeze('/')
    end

    def self.match?(message)
      if match = message.match(/\/content\/\d+\/\d+\/\d+\/(\S*).+(200|206)/)
        # ignore detect.mp4 
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

    def type
      LogMessage.get_type(user_agent)
    end

    def match
      @match ||= @message.match /\/content\/(\d+)\/(\d+)\/+(\d+)\/(\w+\.\w+)*(\?\S*)*\s.*\"\s(\d+)\s(\d+).+"(.*)"$/
    end

    def customer_id
      match[1] if match
    end

    def author_id
      match[2] if match
    end
              
    def project_id
      match[3] if match
    end

    def file
      match[4] if match
    end

    def args
      match[5][1..-1] if match && match[5]
    end

    def status
      match[6].to_i if match
    end

    def bytes
      match[7].to_i if match
    end

    def file_extname
      File.extname(file) if file
    end
    
    def user_agent
      match[8] if match
    end

    def account_info
      {
        customer_id: customer_id,
        author_id: author_id,
        project_id: project_id
      }
    end

    def transfer_info
      {
        status: status,
        bytes: bytes,
        file: file,
        file_extname: file_extname,
        user_agent: user_agent
      }
    end

    def to_h
      account_info.merge(transfer_info)
    end
  end
end 