module SmsLogparser
  class DataCache

    attr_reader :cache

    def initialize
      @cache = Hash.new
    end

    def add(data)
      key = [data[:customer_id], data[:author_id], data[:project_id], data[:type]].join('.')
      @cache[key] = @cache[key].to_i + data[:value].to_i
      @cache
    end

    def data_sets
      @cache.map do |key, value|
        key_components = key.split('.')
        {
          customer_id: key_components[0],
          author_id: key_components[1],
          project_id: key_components[2],
          type: key_components[3],
          value: value
        }
      end
    end

  end # class
end # module