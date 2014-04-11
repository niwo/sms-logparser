module SmsLogparser
  class Cli < Thor
    require 'yaml'

    STATUS = {ok: 0, api_error: 1, running: 3, interrupted: 4}

    class_option :config, 
      default: File.join(Dir.home, '.sms-logparser.yml'),
      aliases: %w(-c),
      desc: "Configuration file for default options"

    class_option :debug, type: :boolean, desc: "Show debug output"
    class_option :logfile, desc: "Path to the logfile (Default: STDOUT)"
    class_option :mysql_host, aliases: %w(-h), desc: "MySQL host"
    class_option :mysql_user, aliases: %w(-u), desc: "MySQL user (Default: root)"
    class_option :mysql_password, aliases: %w(-p), desc: "MySQL password"
    class_option :mysql_db, aliases: %w(-d), desc: "MySQL database (Default: Syslog)"

    desc "version", "Print sms-logparser version number"
    def version
      say "sms-logparser v#{SmsLogparser::VERSION}"
    end
    map %w(-v --version) => :version

    desc "parse", "Check the database for pcache logs and send them to the SMS-API"
    option :api_base_url, aliases: %w(-a),
      desc: "Base path of the SMS API (Default: http://localhost:8080/creator/rest/)"
    option :api_key, aliases: %w(-k), desc: "SMS API Key"
    option :simulate, type: :boolean, aliases: %w(-s),
      desc: "Dry run without submitting any data"
    option :verbose, type: :boolean, aliases: %w(-v), desc: "Verbose output"
    option :limit, type: :numeric, aliases: %w(-l), desc: "Limit the number of entries to query"
    option :accepted_api_responses, type: :array, aliases: %w(-r),
      desc: "API HTTP responses which are accepted (Default: only accept 200)."
    def parse
      start_message = "Parser started"
      start_message += options[:simulate] ? " in simulation mode." : "."
      logger.info(start_message)
      mysql = Mysql.new(options)
      if !options[:simulate] && mysql.parser_running?
        logger.warn("Exit. Another instance of the parser is already running.")
        exit!
      end
      state = {
        last_event_id: mysql.get_last_parse_id, 
        match_count: 0,
        status: STATUS[:running],
        started_at: Time.now,
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
              verbose_parser_output(entry['ID'], data, requests) if options[:verbose]
              state[:last_event_id] = entry['ID']
            end
          end
        end
      end
    rescue SystemExit, Interrupt
      logger.error("Received ctrl-c. Stopping the parser run.")
      state[:status] = STATUS[:interrupted] if state
    rescue => e
      logger.error("#{e.message}. Aborting the parser run.")
      say(e.backtrace.join("\n"), :yellow) if options[:debug]
      state[:status] = STATUS[:api_error] if state
    else
      state[:status] = STATUS[:ok]
    ensure
      begin
        if mysql && state
          state[:run_time] = (Time.now - state[:started_at]).round(2)
          if state[:id]
            mysql.write_parse_result(state) unless options[:simulate]
          end
          log_parse_results(state)
        end
      rescue => e
        logger.fatal(e.message)
        say(e.backtrace.join("\n"), :yellow) if options[:debug]
      end
    end

    desc "history", "List the last paser runs"
    option :results, type: :numeric, default: 10, aliases: %w(-n),
      desc: "Number of results to display"
    option :format, type: :string, default: 'table', aliases: %w(-f),
      desc: "Output format [table|csv]"
    def history
      runs = Mysql.new(options).last_runs(options[:results])
      if runs && runs.size > 0
        table = [%w(id started_at count last_id status run_time)]
        runs.to_a.reverse.each do |run|
          table << [
            run['id'],
            run['run_at'].strftime('%d.%d.%Y %T'),
            run['match_count'],
            run['last_event_id'],
            STATUS.key(run['status']).upcase,
            "#{run['run_time']}s"
          ]
        end
        options[:format] == 'csv' ? 
          table_to_csv(table) :
          print_table(table)
      else
        say "No parser runs found in the database."
      end
    rescue => e
      logger.fatal(e.message)
      say(e.backtrace.join("\n"), :yellow) if options[:debug]
    end

    desc "setup", "Create the parser table to track the last logs parsed"
    option :force, type: :boolean, default: false, aliases: %w(-f),
      desc: "Drop an existing table if it exists"
    def setup
      case Mysql.new(options).create_parser_table(options[:force])
      when 0
        logger.info("Created database table.")
      when 1
        logger.warn("Table already exists.")
      when 2
        logger.info("Recreated database tables.")
      end
    rescue => e
      logger.fatal(e.message)
      say(e.backtrace.join("\n"), :yellow) if options[:debug]
    end

    no_commands do
      def logger
        SmsLogparser::AppLogger.instance.set_log_device(options[:logfile])
      end

      def verbose_parser_output(entry_id, data, requests)
        logger.info {
          "parsing data for #{entry_id} (#{data.map{|k,v| "#{k}=\"#{v || '-'}\""}.join(" ") || ''})"
        }
        logger.info {
          "parser urls for entry #{entry_id} (#{requests.map {|req| "#{req[:url]}#{req[:uri]}"}.join(" ")})"
        }
      end

      def table_to_csv(table)
        table.each do |line|
          puts line.join(',')
        end
      end

      def log_parse_results(res)
        res = res.reject {|k,v| %w(:id :run_at).include? k}
        message = "Parser #{options[:simulate] ? 'simulation' : 'run'} ended."
        message +=  " (" + res.map {|k,v| "#{k}=\"#{v}\""}.join(' ') + ")"
        logger.info(message)
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