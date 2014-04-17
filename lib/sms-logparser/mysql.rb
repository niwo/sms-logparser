module SmsLogparser
  class Mysql

    def initialize(options)
      @options = options
      @query_limit = options[:query_limit] || 5000
      @client = client
      @logger = SmsLogparser::Loggster.instance
      @max_retries = 5
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
      status = 0
      if force
        status = drop_parser_table ? 2 : 0
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
      status 
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
          '#{options[:started_at].strftime("%Y-%m-%d %H:%M:%S")}',\
          #{options[:status]}\
        )"
      )
      options[:id] = client.last_id
      options
    end

    def write_parse_result(options)
      query = %Q{
        UPDATE sms_logparser_runs
        SET last_event_id = #{options[:last_event_id]},
          match_count = #{options[:match_count]},
          status = #{options[:status]},
          run_time = #{options[:run_time]}
        WHERE id = #{options[:id]};
      }.gsub(/\s+/, " ").strip
      retries = 0
      begin
        client.query(query)
      rescue Mysql2::Error => exception
        @logger.error exception
        if (retries += 1) > @max_retries
          @logger.fatal "Can't write parser result to database after #{@max_retries} retries. (#{@query})"
          raise
        end
        sleeptime = @max_retries * retries
        @logger.info "Retry writing parser results in #{sleeptime} seconds."
        sleep sleeptime
        retry 
      end
      true
    end

    def get_entries(options={})
      last_id = options[:last_id] || get_last_parse_id
      max_id = get_max_id(last_id, options[:limit])
      while last_id < max_id
        entries = select_entries(last_id, max_id)
        yield entries
        entries = entries.to_a
        last_id = entries.size > 0 ? entries[-1]['ID'] : max_id
      end
    end

    def get_last_parse_id
      last_parse = client.query(
        "SELECT last_event_id FROM sms_logparser_runs ORDER BY id DESC LIMIT 1;"
      )
      last_parse.first ? last_parse.first['last_event_id'] : 0
    end

    def clean_up_events_table
      last_parse = client.query(
        "SELECT last_event_id FROM sms_logparser_runs WHERE status = 0 ORDER BY id DESC LIMIT 1;"
      )
      if last_parse.first
        id = last_parse.first['last_event_id']
        client.query("DELETE FROM sms_logparser_runs WHERE id < #{id};")
      end
      true
    end

    def clean_up_parser_table(keep_days = 7)
      time = (Time.now - 3600 * 24 * keep_days.to_i).strftime("%Y-%m-%d %H:%M:%S")
      client.query("DELETE FROM sms_logparser_runs WHERE run_at < '#{time}';")
    end

    private

    def get_max_id(last_id, user_limit = nil)
      max_id = get_last_event_id
      if user_limit && user_limit < (max_id - last_id)
        max_id = last_id + user_limit
      end
      max_id
    end

    def select_entries(last_id, max_id)
      query = %Q{
        SELECT ID, Message FROM SystemEvents
        WHERE ID BETWEEN #{last_id + 1} AND #{max_id}
        ORDER BY ID ASC
        LIMIT #{@query_limit};
      }.gsub(/\s+/, " ").strip
      @logger.debug { "Querying for events... (#{query})" }
      client.query(query)
    end

    def get_last_event_id
      last_event = client.query(
        "SELECT MAX(ID) as max_id FROM SystemEvents;"
      )
      last_event.first ? last_event.first['max_id'] : 0
    end

    def parser_table_exists?
      client.query(
        "SHOW TABLES LIKE 'sms_logparser_runs';"
      ).size > 0
    end

    def drop_parser_table
      return false unless parser_table_exists?
      client.query("DROP TABLE sms_logparser_runs;")
      true
    end

  end # class
end # module