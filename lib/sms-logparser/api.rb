module SmsLogparser
  class Api
    require 'uri'
    require 'thread'

    def initialize(options)
      @options = options
      @base_url = URI(@options[:api_base_url] || 'http://localhost:8080/creator/rest/') 
      @url = @base_url.to_s.chomp(@base_url.path)
      @base_path = (@base_url.path << "/").squeeze('/')
      @accepted_responses =  parse_status_codes(options[:accepted_api_responses]) || [200]
      @connection = connection
      @data_cache = {}
    end

    def send(data)
      path = data_to_path(data)
      begin
        if @options[:simulate]
          status = 200
        else
          response = @connection.post(path)
          status = response.status
        end
      rescue => e
        raise RuntimeError, "Can't send request to #{path}. #{e.message}", caller
      end
      unless @accepted_responses.include?(status)
        msg = "Received HTTP status #{status} from API. Only accepting #{@accepted_responses.join(', ')}."
        raise RuntimeError, msg, caller
      end
      return path, status
    end

    def send_sets(data_sets, concurrency=4)
      queue     = Queue.new
      semaphore = Mutex.new
      data_sets.each {|set| queue << set }
      threads = concurrency.times.map do
        Thread.new do
          while !queue.empty?
            path, status = send(queue.pop)
            semaphore.synchronize {
              yield path, status
            }
          end
        end
      end
      threads.each {|thread| thread.join }
    end

    def data_to_path(data)
      @base_path + [
        data[:customer_id],
        data[:author_id],
        data[:project_id],
        data[:type],
        data[:value]
      ].join('/')
    end

    private

    def connection
      connection = Faraday.new(url: @url, request: {timeout: 20}) do |faraday|
        faraday.request :url_encoded
        faraday.adapter :net_http_persistent
        if @options[:severity] == "debug"
          faraday.use Faraday::Response::Logger, SmsLogparser::Loggster.instance
        end
      end
      connection.headers[:user_agent] = "sms-logparser v#{SmsLogparser::VERSION}"
      connection.headers['X-simplex-api-key'] = @options[:api_key] if @options[:api_key]
      connection
    end

    def parse_status_codes(codes)
      codes ? codes.map{|status| status.to_i} : nil
    end

  end # class
end # module