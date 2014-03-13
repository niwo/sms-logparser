module SmsLogparser
  class Cli < Thor

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
      begin
        mysql = Mysql.new(options)
        entries = mysql.get_entries
        api = Api.new(options)
        last_id = mysql.get_last_parse_id
        entries.each do |entry|
          if Parser.match(entry)
            data = Parser.extract_data_from_msg(entry['Message'])
            url = api.send(data)
            last_id = entry['ID']
            count += 1
            debug_parser_output(data, url, entry) if options[:simulate]
          end
        end
        mysql.write_parse_result(last_id, count) unless options[:simulate]
        puts "Started: #{start_time.strftime('%d.%d.%Y %T')}"
        puts "Runtime: #{(Time.now - start_time).round(2)}s"
        puts "Matches: #{count}"
      rescue => e
        say "Error: #{e.message}", :red
      end
    end

    desc "last_runs", "List the last paser runs"
    def last_runs
      begin
        runs = Mysql.new(options).last_runs
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
      rescue => e
        say "Error: #{e.message}", :red
      end
    end

    desc "setup", "Create the parser table to track the last logs parsed"
    def setup
      begin
        Mysql.new(options).create_parser_table
        say "OK", :green
      rescue => e
        say "Error: #{e.message}", :red
      end
    end

    no_commands do
      def debug_parser_output(data, url, entry)
        puts
        say "Message ID: ", :green
        say entry['ID']
        say "URL: ", :green
        say url
        say "Data: ", :green
        say data
        puts
      end
    end

  end
end