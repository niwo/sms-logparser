module SmsLogparser
  class DataCache

    attr_reader :cache

    def initialize
      @cache = Hash.new
      @wanted_keys = [:customer_id, :author_id, :project_id]
    end

    def add(data)
      key = [data[:customer_id], data[:author_id], data[:project_id]].join('.')
      @cache[key] = initialize_value(data) unless @cache.has_key?(key)
      unless data[:file] =~ /.*\.m3u8$/
        @cache[key][data[:traffic_type]] = @cache[key][data[:traffic_type]].to_i + data[:bytes].to_i
      end
      if data[:visitor_type]
        @cache[key][data[:visitor_type]] = @cache[key][data[:visitor_type]].to_i + 1
      end
      @cache
    end

    private

    def initialize_value(data)
      data.select { |key,_| @wanted_keys.include? key }
    end

  end # class
end # module