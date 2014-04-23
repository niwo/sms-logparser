module SmsLogparser
  class DataCache

    attr_reader :cache

    def initialize
      @cache = Hash.new
      @identifier_keys = %w(:customer_id :author_id :project_id :type)
    end

    def add(data)
      key = [data[:customer_id], data[:author_id], data[:project_id], data[:type]].join('.')
      @cache[key] = initialize_value(data) unless @cache.has_key?(key)
      @cache[key][:value] = @cache[key][:value].to_i + data[:value].to_i
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

    private

    def initialize_value(data)
      data.select { |key,_| @identifier_keys.include? key }
    end

  end # class
end # module