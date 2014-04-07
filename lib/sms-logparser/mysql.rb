module SmsLogparser
  class Mysql

    def initialize(options)
      @options = options
      @host_filter = options[:host_filter] || 'pcache%'
      @query_limit = options[:query_limit] || 1000
      @client = client
    end

    def client
      @client ||= Mysql2::Client.new(
        host: @options[:mysql_host],
        username: @options[:mysql_user] || "root",
        password: @options[:mysql_password],
        database: @options[:mysql_db] || "Syslog"
      )
    end

    def last_runs(results = 10)
      runs = client.query(
        "SELECT * FROM sms_logparser_runs ORDER BY id DESC LIMIT #{results || 10}"
      )
    end

    def create_parser_table(force = false)
      if force
        drop_parser_table
      elsif parser_table_exists?
        return 1
      end
      client.query(
        "CREATE TABLE sms_logparser_runs(\
          id SERIAL PRIMARY KEY AUTO_INCREMENT,\
          run_at datetime DEFAULT NULL,\
          last_event_id BIGINT(20) UNSIGNED DEFAULT 0,\
          match_count INT UNSIGNED DEFAULT 0,\
          status TINYINT UNSIGNED DEFAULT 0,\
          run_time DOUBLE(10,2) NOT NULL DEFAULT '0.00',\
          INDEX `last_event_id_I1` (`last_event_id`)
        )"
      )
      return 0
    end

    def parser_running?(running_state = 3)
      last_parse = client.query(
        "SELECT status FROM sms_logparser_runs ORDER BY id DESC LIMIT 1"
      )
      if entry = last_parse.first
        return entry['status'] == running_state ? true : false
      end
      false
    end

    def start_run(options)
      client.query(
        "INSERT INTO sms_logparser_runs (run_at, status)\
        VALUES (\
          '#{options[:run_at].strftime("%Y-%m-%d %H:%M:%S")}',\
          #{options[:status]}\
        )"
      )
      options[:id] = client.last_id
      options
    end

    def write_parse_result(options)
      client.query(
        "UPDATE sms_logparser_runs SET\
          last_event_id = #{options[:last_event_id]},\
          match_count = #{options[:match_count]},\
          status = #{options[:status]},\
          run_time = #{options[:run_time]}\
        WHERE id = #{options[:id]}"
      )
    end

    def get_entries(options={})
      last_id = options[:last_id] || get_last_parse_id
      max_id, query_limit = get_query_limits(last_id, options[:limit])
      while last_id < max_id
        entries = select_entries(last_id, query_limit)
        yield entries
        entries = entries.to_a
        last_id = entries.size > 0 ? entries[-1]['ID'] : max_id
      end
    end

    def get_last_parse_id
      last_parse = client.query(
        "SELECT last_event_id FROM sms_logparser_runs ORDER BY id DESC LIMIT 1"
      )
      last_parse.first ? last_parse.first['last_event_id'] : 0
    end

    private

    def get_query_limits(last_id, user_limit = nil)
      if user_limit
        max_id = last_id + user_limit
        if @query_limit > user_limit
          query_limit = user_limit
        end
      else 
        max_id = get_last_event_id
      end
      [max_id, query_limit || @query_limit]
    end

    def select_entries(offset, max_entries = @query_limit)
      client.query(
        "SELECT * FROM SystemEvents\
        WHERE `FromHost` like '#{@host_filter}'\
        ORDER BY ID ASC\
        LIMIT #{offset},#{max_entries};"
      )
    end

    def get_last_event_id
      last_event = client.query(
        "SELECT ID FROM SystemEvents ORDER BY ID DESC LIMIT 1"
      )
      last_event.first ? last_event.first['ID'] : 0
    end

    def parser_table_exists?
      client.query(
        "SHOW TABLES LIKE 'sms_logparser_runs'"
      ).size > 0
    end

    def drop_parser_table
      return nil unless parser_table_exists?
      client.query("DROP TABLE sms_logparser_runs")
    end

  end # class
end # module