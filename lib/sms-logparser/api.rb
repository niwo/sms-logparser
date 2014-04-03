module SmsLogparser
  class Api

    def initialize(options)
      @options = options
    end

    def connection
      @connection ||= new_connection
    end

    def new_connection
      base_url = @options[:api_base_path] || 'http://localhost:8080'
      conn = Faraday.new(url: base_url) do |faraday|
        faraday.request :url_encoded
        faraday.response :logger if @options[:debug]
        faraday.adapter  Faraday.default_adapter
      end
      conn.headers[:user_agent] = "sms-logparser v#{SmsLogparser::VERSION}"
      if @options[:api_key]
        conn.headers['X-simplex-api-key'] = @options[:api_key]
      end
      conn
    end

    def send(data)
      uris = []
      base_uri = ["/#{data[:customer_id]}", data[:author_id], data[:project_id]].join('/')
      unless data[:file] =~ /.*\.m3u8$/
        uris << [base_uri, data[:traffic_type], data[:bytes]].join('/')
      end
      if data[:visitor_type]
        uris << [base_uri, data[:visitor_type], 1].join('/')
      end
      unless @options[:simulate]
        uris.each do |uri|
          begin
            response = connection.post(uri)
          rescue => e
            raise RuntimeError, "Can't send request to #{uri}. #{e.message}", caller
          end
          unless response.status == 200
            raise RuntimeError, "Received response code (#{response.status}) from API.", caller
          end
        end
      end
      uris
    end

  end # class
end # module