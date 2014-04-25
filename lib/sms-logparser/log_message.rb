module SmsLogparser
  class LogMessage

    attr_reader :message

    MOBILE_AGENT  = '.*(Mobi|IEMobile|Mobile Safari|iPhone|iPod|iPad|Android|BlackBerry|Opera Mini).*'
    PODCAST_AGENT = '.*(iTunes).*'
    FILE_EXCLUDE  = 'detect.mp4'
    STATUS_MATCH  = '200|206'

    def initialize(message, options = {})
      # remove double slashes from message
      @message = message.squeeze('/')
      @mobile_agent = options[:mobile_agent_regex] || MOBILE_AGENT
      @podcast_agent = options[:podcast_agent_regex] || PODCAST_AGENT
      @file_exclude = options[:file_exclude_regex] || FILE_EXCLUDE
      @status_match = options[:status_match_regex] || STATUS_MATCH
    end

    def match?
      if match = @message.match(/\/content\/\d+\/\d+\/\d+\/(\S*).+(#{@status_match})/)
        # ignore detect.mp4 
        return true unless match[1] =~ /#{@file_exclude}/i
      end
      false
    end

    # see https://developer.mozilla.org/en-US/docs/Browser_detection_using_the_user_agent
    # for mobile browser detection
    def self.get_type(user_agent, mobile_agent = MOBILE_AGENT, podcast_agent = PODCAST_AGENT)
      case user_agent
      when /#{podcast_agent}/i
        'PODCAST'
      when /#{mobile_agent}/i
        'MOBILE'
      else
        'WEBCAST'
      end
    end

    def type
      LogMessage.get_type(user_agent, @mobile_agent, @podcast_agent)
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