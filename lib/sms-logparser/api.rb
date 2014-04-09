module SmsLogparser
  class Api
    require 'uri'

    def initialize(options)
      @options = options
      @base_url = URI(@options[:api_base_url] || 'http://localhost:8080/creator/rest/') 
      @url = @base_url.to_s.chomp(@base_url.path)
      @base_path = (@base_url.path << "/").squeeze('/')
      @accepted_responses =  parse_status_codes(options[:accepted_api_responses]) || [200]
      @connection = connection
    end

    def send(data)
      requests = []
      path = @base_path << [data[:customer_id], data[:author_id], data[:project_id]].join('/')
      unless data[:file] =~ /.*\.m3u8$/
        requests << {
          url: @url, 
          uri: [path, data[:traffic_type], data[:bytes]].join('/'),
        }
      end
      if data[:visitor_type]
        requests << {
          url: @url,
          uri: [path, data[:visitor_type], 1].join('/')
        }
      end
      unless @options[:simulate]
        requests.each_with_index do |request, i|
          begin
            response = @connection.post(request[:uri])
            requests[i][:status] = response.status
          rescue => e
            raise RuntimeError, "Can't send request to #{request[:uri]}. #{e.message}", caller
          end
          unless @accepted_responses.include?(response.status)
            msg = "Received HTTP status #{response.status} from API. Only accepting #{@accepted_responses.join(', ')}."
            raise RuntimeError, msg, caller
          end
        end
      end
      requests
    end

    private

    def connection
      connection = Faraday.new(url: @url, request: {timeout: 5}) do |faraday|
        faraday.request :url_encoded
        if @options[:debug]
          faraday.use Faraday::Response::Logger, SmsLogparser::AppLogger.instance 
        end
        faraday.adapter :net_http_persistent
      end
      connection.headers[:user_agent] = "sms-logparser v#{SmsLogparser::VERSION}"
      if @options[:api_key]
        connection.headers['X-simplex-api-key'] = @options[:api_key]
      end
      connection
    end

    def parse_status_codes(codes)
      codes ? codes.map{|status| status.to_i} : nil
    end

  end # class
end # module