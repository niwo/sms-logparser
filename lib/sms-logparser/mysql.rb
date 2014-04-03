module SmsLogparser
  class Mysql

    def initialize(options)
      @options = options
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
      begin 
        runs = client.query(
          "SELECT * FROM SmsParserRuns ORDER BY ID DESC LIMIT #{results}"
        )
      rescue Mysql2::Error => e
        raise e
      end
    end

    def parser_table_exists?
      begin
        return client.query(
          "SHOW TABLES LIKE 'SmsParserRuns'"
        ).size > 0
      rescue Mysql2::Error => e
        raise e
      end
    end

    def create_parser_table(force = false)
      if force
        drop_parser_table
      elsif parser_table_exists?
        return 1
      end
      begin
        client.query(
          "CREATE TABLE SmsParserRuns(\
            ID SERIAL PRIMARY KEY AUTO_INCREMENT,\
            RunAt datetime DEFAULT NULL,\
            LastEventID BIGINT(20) UNSIGNED DEFAULT 0,\
            EventsFound INT DEFAULT 0,\
            Status TINYINT UNSIGNED DEFAULT 0,\
            INDEX `LastEventID_I1` (`LastEventID`)
          )"
        )
      rescue Mysql2::Error => e
        raise e
      end
      return 0
    end

    def drop_parser_table
      return nil unless parser_table_exists?
      begin
        return client.query(
          "DROP TABLE SmsParserRuns"
        )
      rescue Mysql2::Error => e
        raise e
      end
    end

    def get_entries(last_id = get_last_parse_id)
      begin 
        return client.query(
          "SELECT * FROM SystemEvents\
          WHERE `FromHost` like 'pcache%'\
          AND ID > #{last_id} ORDER BY ID ASC"
        )
      rescue Mysql2::Error => e
        raise e
      end
    end

    def write_parse_result(id, count, status)
      client.query("INSERT INTO SmsParserRuns(RunAt, LastEventID, EventsFound, Status)\
        VALUES(\
          '#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}',\
          #{id},\
          #{count},\
          #{status}
        )"
      )
    end

    def get_last_parse_id
      id = 0
      begin
        last_parse = client.query(
          "SELECT LastEventID FROM SmsParserRuns ORDER BY ID DESC LIMIT 1"
        )
        id = last_parse.first ? last_parse.first['LastEventID'] : 0
      rescue Mysql2::Error => e
        raise e
      end
      id
    end

  end # class
end # module