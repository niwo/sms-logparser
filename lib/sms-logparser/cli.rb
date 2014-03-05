module SmsLogparser 
  class Cli < Thor

    EXTENSION_MAP = {
      'default' => 'TRAFFIC_PODCAST',
      'mp4' => 'TRAFFIC_PODCAST',
      'f4v' => 'TRAFFIC_PODCAST',
      'flv' => 'TRAFFIC_PODCAST',
      'ts' => 'TRAFFIC_MOBILE'
    }

    class_option :mysql_host, :default => 'localhost'
    class_option :mysql_user, :default => 'root'
    class_option :mysql_db, :default => 'Syslog'

    desc "version", "print cloudstack-cli version number"
    def version
      say "sms-logparser version #{SmsLogparser::VERSION}"
    end
    map %w(-v --version) => :version

    desc "parse", "Check the database for pcache logs and send them to SMS"
    option :api_base_path, :default => 'http://dev.simplex.tv/creator/rest'
    option :simulate, :type => :boolean, :default => false
    def parse
      start_time = Time.now
      count = 0
      last_id = get_last_parse_id 
      begin 
        results = client.query(
          "SELECT * FROM SystemEvents\
          WHERE `FromHost` like 'pcache%'\
          AND ID > #{last_id} ORDER BY ID ASC"
        )
      rescue Mysql2::Error
        say "parser_table not found please create it with 'create_parser_table'", :red
        exit 1
      end
      results.each do |result|
        if result['Message'] =~ /\/content\/.*\.(f4v|flv|mp4|ts) .*/
          data = extract_data_from_msg(result['Message'])
          url = "#{options[:api_base_path]}/"
          url += "#{data[:customer_id]}/"
          url += "#{data[:author_id]}/"
          url += "#{data[:project_id]}/"
          url += "#{data[:traffic_type]}/"
          url += "#{data[:bytes]}"
          if options[:simulate]
            puts "Message ID: #{result['ID']}"
            puts "URL: #{url}"
            puts "Data: #{data}"
            puts "-----------------------"
          else
            begin
              RestClient.get(url)
            rescue
              say "Error: Can't send log to #{url}", :red
              say "Aborting.", :red
              break
            end
          end
          count += 1
        end
        last_id = result['ID']
      end
      write_parse_result(last_id, count) unless options[:simulate]
      puts "Started: #{start_time.strftime('%d.%d.%Y %T')}"
      puts "Runtime: #{(Time.now - start_time).round(2)}s"
      puts "Matches: #{count}"
    end

    desc "last_runs", "List the last paser runs"
    def last_runs
      begin 
        runs = client.query(
          "SELECT * FROM SmsParserRuns ORDER BY ID ASC LIMIT 10"
        )
      rescue Mysql2::Error
        say "parser_table not found please create it with 'create_parser_table'", :red
        exit 1
      end
      if runs.size > 0
        table = [%w(RunAt #Events LastEventID)]
        runs.each do |run|
          table << [
            run['RunAt'],
            run['EventsFound'],
            run['LastEventID']
          ]
        end
        print_table table
      else
        say "No parser runs found in the database."
      end
    end

    desc "create_parser_table", "Create the parser table to track the last logs parsed"
    def create_parser_table
      client.query(
        "CREATE TABLE IF NOT EXISTS\
          SmsParserRuns(\
            ID INT PRIMARY KEY AUTO_INCREMENT,\
            RunAt datetime DEFAULT NULL,\
            LastEventID INT DEFAULT NULL,\
            EventsFound INT DEFAULT 0,\
            INDEX `LastEventID_I1` (`LastEventID`)
          )"
      )
      say "OK", :green
    end

    no_commands do
      def get_last_parse_id
        last_parse = client.query(
          "SELECT LastEventID FROM SmsParserRuns ORDER BY ID DESC LIMIT 1"
        )
        last_parse.first ? last_parse.first['LastEventID'] : 0
      rescue Mysql2::Error
        say "parser_table not found please create it with 'create_parser_table'", :red
        exit 1
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

      def extract_data_from_msg(msg)
        m = msg.match /\/content\/(\d+)\/(\d+)\/(\d+)\/.+\.(\S+)\s.*\"\s\d+\s(\d+)/
        data = {
          :customer_id => m[1],
          :author_id => m[2],
          :project_id => m[3],
          :ext => m[4],
          :traffic_type => (EXTENSION_MAP[m[4]] || EXTENSION_MAP['default']),
          :bytes => m[5]
        }
      end

      def client
        @client ||= Mysql2::Client.new(
          :host => options[:mysql_host],
          :username => options[:mysql_user],
          :database => options[:mysql_db]
        )
      end
    end
  end
end