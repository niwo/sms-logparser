module SmsLogparser
  class LogMessage
    def initialize(message)
      @message = message
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