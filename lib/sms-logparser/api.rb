module SmsLogparser
  class Api

    def initialize(options)
      @options = options
    end

    def send(data)
      url = "#{@options[:api_base_path]}/"
      url += "#{data[:customer_id]}/"
      url += "#{data[:author_id]}/"
      url += "#{data[:project_id]}/"
      url += "#{data[:traffic_type]}/"
      url += "#{data[:bytes]}"
      unless @options[:simulate]
        begin
          RestClient.get(url)
        rescue
          raise "Can't send log to #{url}"
        end
      end
      url
    end

  end # class
end # module