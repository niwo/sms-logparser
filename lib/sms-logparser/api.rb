module SmsLogparser
  class Api

    def initialize(options)
      @options = options
    end

    def send(data)
      base_url = "#{@options[:api_base_path]}/"
      base_url += "#{data[:customer_id]}/"
      base_url += "#{data[:author_id]}/"
      base_url += "#{data[:project_id]}"
      urls = ["#{base_url}/#{data[:traffic_type]}/#{data[:bytes]}"]
      urls << "#{base_url}/#{data[:visitor_type]}/1" if data[:visitor_type]
      unless @options[:simulate]
        urls.each do |url|
          begin
            RestClient::Request.execute(
              :method   => :post,
              :url      => url,
              :headers  => {
                'X-simplex-api-key' => @options[:api_key]
              }
            )
          rescue
            raise "Can't send request to #{url}"
          end
        end
      end
      urls
    end

  end # class
end # module