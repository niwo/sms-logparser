module SmsLogparser
  class Parser

    def self.extract_data_from_msg(msg)
      m = msg.match /\/content\/(\d+)\/(\d+)\/(\d+)\/.+\.(\S+)\s.*\"\s\d+\s(\d+).+"(.*)"$/
      raise "No match found." unless m
      data = {
        :customer_id => m[1],
        :author_id => m[2],
        :project_id => m[3],
        :ext => m[4],
        :traffic_type => Parser.get_traffic_type(m[4]),
        :bytes => m[5],
        :user_agent => m[6]
      }
    end

    def self.match(entry)
      entry['Message'] =~ /\/content\/.*\.(f4v|flv|mp4|mp3|ts) .*/
    end

    def self.get_traffic_type(user_agent)
      case user_agent
      when /.*(iTunes).*/
        "TRAFFIC_PODCAST"
      when /.*(IEMobile|Mobile Safari|iPhone|iPod|iPad).*/
        "TRAFFIC_MOBILE"
      else
        "TRAFFIC_WEBCAST"
      end
    end

  end # class
end # module