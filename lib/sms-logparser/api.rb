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
      requests = build_urls(data)
      return requests if @options[:simulate]

      threads = requests.map do |request|
        Thread.new do
          begin
            response = @connection.post(request[:uri])
            request[:status] = response.status
          rescue => e
            raise RuntimeError, "Can't send request to #{request[:uri]}. #{e.message}", caller
          end
          unless @accepted_responses.include?(response.status)
            msg = "Received HTTP status #{response.status} from API. Only accepting #{@accepted_responses.join(', ')}."
            raise RuntimeError, msg, caller
          end
        end
      end
      threads.each {|thread| thread.join }
      requests
    end

    def send_from_queue(data_sets)
      queue     = Queue.new
      semaphore = Mutex.new
      data_sets.each {|set| queue << set }
      threads = 4.times.map do
        Thread.new do
          while !queue.empty?
            begin
              data = queue.pop
              url = @base_path + [
                data[:customer_id],
                data[:author_id],
                data[:project_id],
                data[:type],
                data[:value]
              ].join('/')
              if @options[:simulate]
                semaphore.synchronize {
                  yield url, 0
                }
                break
              end
              response = @connection.post(url)
            rescue => e
              raise RuntimeError, "Can't send request to #{url}. #{e.message}", caller
            end
            unless @accepted_responses.include?(response.status)
              msg = "Received HTTP status #{response.status} from API. Only accepting #{@accepted_responses.join(', ')}."
              raise RuntimeError, msg, caller
            end
            semaphore.synchronize {
              yield url, response.status
            }
          end
        end
      end
      threads.each {|thread| thread.join }
    end

    def build_urls(data)
      requests = []
      path = @base_path + [data[:customer_id], data[:author_id], data[:project_id]].join('/')
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
      requests
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