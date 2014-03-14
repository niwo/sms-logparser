module SmsLogparser
  class Mysql

    def initialize(options)
      @options = options
    end

    def client
      @client ||= Mysql2::Client.new(
        :host => @options[:mysql_host],
        :username => @options[:mysql_user],
        :password => @options[:mysql_password],
        :database => @options[:mysql_db]
      )
    end

    def last_runs
      begin 
        runs = client.query(
          "SELECT * FROM SmsParserRuns ORDER BY ID ASC LIMIT 10"
        )
      rescue Mysql2::Error => e
        raise e
      end
    end

    def create_parser_table
      begin
        return client.query(
          "CREATE TABLE IF NOT EXISTS\
            SmsParserRuns(\
              ID INT PRIMARY KEY AUTO_INCREMENT,\
              RunAt datetime DEFAULT NULL,\
              LastEventID INT DEFAULT NULL,\
              EventsFound INT DEFAULT 0,\
              INDEX `LastEventID_I1` (`LastEventID`)
            )"
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

    def write_parse_result(id, count)
      client.query("INSERT INTO SmsParserRuns(RunAt, LastEventID, EventsFound)\
        VALUES(\
          '#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}',\
          #{id},\
          #{count}
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