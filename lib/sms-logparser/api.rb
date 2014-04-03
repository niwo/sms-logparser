module SmsLogparser
  class Api
    require 'uri'

    def initialize(options)
      @options = options
      @base_url = URI(@options[:api_base_url] || 'http://localhost:8080/creator/rest')
    end

    def connection
      @connection ||= new_connection
    end

    def new_connection
      conn = Faraday.new(url: @base_url) do |faraday|
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
      base_path = [@base_url.path, data[:customer_id], data[:author_id], data[:project_id]].join('/')
      unless data[:file] =~ /.*\.m3u8$/
        uris << [base_path, data[:traffic_type], data[:bytes]].join('/')
      end
      if data[:visitor_type]
        uris << [base_path, data[:visitor_type], 1].join('/')
      end
      unless @options[:simulate]
        uris.each do |uri|
          begin
            response = connection.post(uri)
          rescue => e
            raise RuntimeError, "Can't send request to #{uri}. #{e.message}", caller
          end
          unless response.status == 200
            raise RuntimeError, "Received HTTP status #{response.status} from API.", caller
          end
        end
      end
      uris
    end

  end # class
end # module