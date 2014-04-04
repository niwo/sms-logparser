module SmsLogparser
  class Cli < Thor
    require 'yaml'

    STATUS = {
      :ok => 0,
      :api_error => 1
    }

    class_option :config, 
      default: File.join(Dir.home, '.sms-logparser.yml'),
      aliases: %w(-c),
      desc: "Configuration file for default options"

    class_option :mysql_host, 
      aliases: %w(-h),
      desc: "MySQL host"
    
    class_option :mysql_user,
      aliases: %w(-u),
      desc: "MySQL user (default: root)"
    
    class_option :mysql_password,
      aliases: %w(-p),
      desc: "MySQL password"
    
    class_option :mysql_db,
      aliases: %w(-d),
      desc: "MySQL database (default: Syslog)"

    desc "version", "Print sms-logparser version number"
    def version
      say "sms-logparser v#{SmsLogparser::VERSION}"
    end
    map %w(-v --version) => :version

    desc "parse", "Check the database for pcache logs and send them to the SMS-API"
    option :api_base_url,
      aliases: %w(-a),
      desc: "Base path of the SMS API (default: http://localhost:8080/)"
    option :api_key,
      aliases: %w(-k)
    option :simulate,
      type: :boolean,
      default: false,
      aliases: %w(-s)
    option :verbose,
      type: :boolean,
      default: false,
      aliases: %w(-v)
    option :limit,
      type: :numeric,
      aliases: %w(-l)
    option :debug,
      type: :boolean,
      default: false
    def parse
      say "Starting the parser...", :green
      start_time = Time.now
      count = 0
      begin
        mysql = Mysql.new(options)
        api = Api.new(options)
        last_id = mysql.get_last_parse_id
        status = STATUS[:ok]
        begin
          mysql.get_entries(last_id: last_id, limit: options[:limit]) do |entries|
            entries.each do |entry| 
              if data = Parser.extract_data_from_msg(entry['Message'])
                uris = api.send(data)
                last_id = entry['ID']
                count += 1
                if options[:verbose]
                  verbose_parser_output(data, uris, entry)
                end
              end
            end
          end
        rescue => e
          say "Error: #{e.message}", :red
          say "Aborting parser run...", :red
          status = STATUS[:api_error]
        ensure
          mysql.write_parse_result(
            last_event_id: last_id, 
            match_count: count,
            status: status,
            run_at: start_time,
            run_time: (Time.now - start_time).round(2)
          ) unless options[:simulate]
        end
        say "Started:\t", :cyan
        say start_time.strftime('%d.%d.%Y %T')
        say "Runtime:\t", :cyan
        say "#{(Time.now - start_time).round(2)}s"
        say "Status:\t\t", :cyan
        say STATUS.key(status).upcase
        action = options[:simulate] ? "found" : "sent"
        say("Events #{action}:\t", :cyan)
        say count
      rescue => e
        say "Error: #{e.message}", :red
        say e.backtrace; :yellow
      end
    end

    desc "history", "List the last paser runs"
    option :results,
      type: :numeric,
      default: 10,
      aliases: %w(-n),
      desc: "Number of results to display"
    def history
      begin
        runs = Mysql.new(options).last_runs(options[:results])
        if runs.size > 0
          table = [%w(run_at run_time match_count last_event_id status)]
          runs.to_a.reverse.each do |run|
            table << [
              run['run_at'],
              "#{run['run_time']}s",
              run['match_count'],
              run['last_event_id'],
              STATUS.key(run['status']).upcase
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
    option :force,
      type: :boolean,
      default: false,
      aliases: %w(-f),
      desc: "Drop an existing table if it exists"
    def setup
      begin
        case Mysql.new(options).create_parser_table(options[:force])
        when 0
          say "OK, table created.", :green
        when 1
          say "Table already exists.", :yellow
        end
      rescue => e
        say "Error: #{e.message}", :red
      end
    end

    no_commands do
      def verbose_parser_output(data, uris, entry)
        say "ID:\t", :cyan
        say entry['ID']
        say "URI:\t", :cyan
        say uris.join("\n\t")
        say "Data:\t", :cyan
        say data.map{|k,v| "#{k}:\t#{v}"}.join("\n\t") || "\n"
        puts
        puts "-" * 100
        puts
      end

      def options
        original_options = super
        filename = original_options[:config] || File.join(Dir.home, '.sms-logparser.yml')
        return original_options unless File.exists?(filename)
        defaults = ::YAML::load_file(filename) || {}
        Thor::CoreExt::HashWithIndifferentAccess.new(defaults.merge(original_options))
      end
    end

  end
end