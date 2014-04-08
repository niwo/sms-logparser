module SmsLogparser
  class Cli < Thor
    require 'yaml'

    STATUS = {ok: 0, api_error: 1, running: 3}

    class_option :config, 
      default: File.join(Dir.home, '.sms-logparser.yml'),
      aliases: %w(-c),
      desc: "Configuration file for default options"

    class_option :mysql_host, 
      aliases: %w(-h),
      desc: "MySQL host"
    
    class_option :mysql_user,
      aliases: %w(-u),
      desc: "MySQL user (Default: root)"
    
    class_option :mysql_password,
      aliases: %w(-p),
      desc: "MySQL password"
    
    class_option :mysql_db,
      aliases: %w(-d),
      desc: "MySQL database (Default: Syslog)"

    desc "version", "Print sms-logparser version number"
    def version
      say "sms-logparser v#{SmsLogparser::VERSION}"
    end
    map %w(-v --version) => :version

    desc "parse", "Check the database for pcache logs and send them to the SMS-API"
    option :api_base_url,
      aliases: %w(-a),
      desc: "Base path of the SMS API (Default: http://localhost:8080/creator/rest/)"
    option :api_key,
      aliases: %w(-k),
      desc: "SMS API Key"
    option :simulate,
      type: :boolean,
      default: false,
      aliases: %w(-s),
      desc: "Dry run without submitting any data"
    option :verbose,
      type: :boolean,
      default: false,
      aliases: %w(-v),
      desc: "Verbose output"
    option :limit,
      type: :numeric,
      aliases: %w(-l),
      desc: "Limit the number of entries to query"
    option :debug,
      type: :boolean,
      default: false,
      desc: "Show debug output"
    option :accepted_api_responses,
      type: :array,
      desc: "API HTTP responses which are accepted (Default: only accept 200)."
    def parse
      say "Starting the parser...", :green
      mysql = Mysql.new(options)
      if !options[:simulate] && mysql.parser_running?
        say "Exit. Another instance of the parser is already running.", :yellow
        exit
      end
      state = {
        last_event_id: mysql.get_last_parse_id, 
        match_count: 0,
        status: STATUS[:running],
        run_at: Time.now,
        run_time: 0.0
      }
      state = mysql.start_run(state) unless options[:simulate]
      api = Api.new(options)
      mysql.get_entries(last_id: state[:last_event_id], limit: options[:limit]) do |entries|
        entries.each do |entry| 
          Parser.extract_data_from_msg(entry['Message']) do |data|
            if data
              requests = api.send(data)
              state[:match_count] += 1
              verbose_parser_output(data, requests, entry['ID']) if options[:verbose]
            end
          end
          state[:last_event_id] = entry['ID']
        end
      end
      state[:status] = STATUS[:ok]
    rescue => e
      say "Error: #{e.message}", :red
      say "Aborting parser run...", :red
      say(e.backtrace.join("\n"), :yellow) if options[:debug]
      state[:status] = STATUS[:api_error] if state
    ensure
      begin
        if mysql && state
          state[:run_time] = (Time.now - state[:run_at]).round(2)
          if state[:id]
            mysql.write_parse_result(state) unless options[:simulate]
          end
          print_parse_results(state)
        end
      rescue => e
        say "Error: #{e.message}", :red
        say(e.backtrace.join("\n"), :yellow) if options[:debug]
      end
    end

    desc "history", "List the last paser runs"
    option :results,
      type: :numeric,
      default: 10,
      aliases: %w(-n),
      desc: "Number of results to display"
    def history
      runs = Mysql.new(options).last_runs(options[:results])
      if runs && runs.size > 0
        table = [%w(run_at count last_id status run_time)]
        runs.to_a.reverse.each do |run|
          table << [
            run['run_at'].strftime('%d.%d.%Y %T'),
            run['match_count'],
            run['last_event_id'],
            STATUS.key(run['status']).upcase,
            "#{run['run_time']}s"
          ]
        end
        print_table table
      else
        say "No parser runs found in the database."
      end
    rescue => e
      say "Error: #{e.message}", :red
      exit 1
    end

    desc "setup", "Create the parser table to track the last logs parsed"
    option :force,
      type: :boolean,
      default: false,
      aliases: %w(-f),
      desc: "Drop an existing table if it exists"
    def setup
      case Mysql.new(options).create_parser_table(options[:force])
      when 0
        say "OK, table created.", :green
      when 1
        say "Table already exists.", :yellow
      end
    rescue => e
      say "Error: #{e.message}", :red
      exit 1
    end

    no_commands do
      def verbose_parser_output(data, requests, entry_id)
        say "ID:\t", :cyan
        say entry_id
        say "URL:\t", :cyan
        say requests.map {|req| "#{req[:url]}#{req[:uri]} (Status: #{req[:status] || 'n/a'})"}.join("\n\t")
        say "Data:\t", :cyan
        say data.map{|k,v| "#{k}:\t#{v || '-'}"}.join("\n\t") || "\n"
        puts
        puts "-" * 100
        puts
      end

      def print_parse_results(res)
        say "Started:\t", :cyan
        say res[:run_at].strftime('%d.%d.%Y %T')
        say "Runtime:\t", :cyan
        say "#{res[:run_time]}s"
        say "Status:\t\t", :cyan
        say STATUS.key(res[:status]).upcase
        say("Events #{options[:simulate] ? "found" : "sent"}:\t", :cyan)
        say res[:match_count]
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