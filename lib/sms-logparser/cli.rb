module SmsLogparser
  class Cli < Thor

    class_option :mysql_host, :default => 'localhost', aliases: %w(-h)
    class_option :mysql_user, :default => 'root', aliases: %w(-u)
    class_option :mysql_password, aliases: %w(-p)
    class_option :mysql_db, :default => 'Syslog', aliases: %w(-d)

    desc "version", "print cloudstack-cli version number"
    def version
      say "sms-logparser version #{SmsLogparser::VERSION}"
    end
    map %w(-v --version) => :version

    desc "parse", "Check the database for pcache logs and send them to SMS"
    option :api_base_path, :default => 'http://dev.simplex.tv/creator/rest', aliases: %w(-a)
    option :simulate, :type => :boolean, :default => false, aliases: %w(-s)
    option :verbose, :type => :boolean, :default => false, aliases: %w(-v)
    def parse
      start_time = Time.now
      count = 0
      begin
        mysql = Mysql.new(options)
        entries = mysql.get_entries
        api = Api.new(options)
        last_id = mysql.get_last_parse_id
        entries.each do |entry|
          if Parser.match(entry['Message'])
            data = Parser.extract_data_from_msg(entry['Message'])
            begin
              urls = api.send(data)
            rescue => e
              say "Error: #{e.message}", :red
              say "Aborting parser run...", :red
              break
            end
            last_id = entry['ID']
            count += 1
            verbose_parser_output(data, urls, entry) if options[:verbose]
          end
        end
        mysql.write_parse_result(last_id, count) unless options[:simulate]
        say "Started:\t", :cyan
        say start_time.strftime('%d.%d.%Y %T')
        say "Runtime:\t", :cyan
        say "#{(Time.now - start_time).round(2)}s"
        options[:simulate] ? say("Events found:\t", :cyan) : say("Events sent:\t", :cyan)
        say count
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
      def verbose_parser_output(data, urls, entry)
        say "ID:\t", :cyan
        say entry['ID']
        say "URL:\t", :cyan
        say urls.join("\n\t")
        say "Data:\t", :cyan
        say data.map{|k,v| "#{k}:\t#{v}"}.join("\n\t")
        puts "-" * 100
        puts
      end
    end

  end
end