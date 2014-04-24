module SmsLogparser
  class Cli < Thor
    require 'yaml'

    STATUS = {ok: 0, api_error: 1, running: 3, interrupted: 4, unknown: 5}

    class_option :config, 
      default: File.join(Dir.home, '.sms-logparser.yml'),
      aliases: %w(-c),
      desc: "Configuration file for default options"

    class_option :severity, type: :string, aliases: %w(-S),
      desc: "Log severity <DEBUG|INFO|WARN|ERROR|FATAL> (Default: INFO)"
    class_option :logfile, desc: "Path to the logfile (Default: STDOUT)", aliases: %w(-l)
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
    option :limit, type: :numeric, aliases: %w(-L), desc: "Limit the number of entries to query"
    option :accepted_api_responses, type: :array, aliases: %w(-r),
      desc: "API HTTP responses which are accepted (Default: only accept 200)"
    option :accumulate, type: :boolean, aliases: %w(-A), default: true,
      desc: "Accumulate and cache results and send totals"
    option :concurrency, type: :numeric, default: 4, aliases: %w(-C),
      desc: "How many threads to use in parallel when sending cached results"
    option :webcast_traffic_correction, type: :numeric, aliases: %w(-W),
      desc: "Correction factor for webcast traffic"
    option :mobile_traffic_correction, type: :numeric, aliases: %w(-M),
      desc: "Correction factor for mobile traffic"
    option :podcast_traffic_correction, type: :numeric, aliases: %w(-P),
      desc: "Correction factor for podcast traffic"
    def parse
      start_message = "Parser started"
      start_message += options[:simulate] ? " in simulation mode." : "."
      logger.debug("Parser options: #{options.inspect}")
      logger.info(start_message)
      parser = Parser.new(options)
      cache = DataCache.new if options[:accumulate]
      mysql = Mysql.new(options)
      if !options[:simulate] && mysql.parser_running?
        logger.warn("Exit. Another instance of the parser is already running.")
        SmsLogparser::Loggster.instance.close
        exit!
      end
      state = {
        last_event_id: mysql.get_last_parse_id, 
        match_count: 0,
        status: STATUS[:running],
        started_at: Time.now,
        run_time: 0.0
      }
      state[:id] = mysql.start_run(state) unless options[:simulate]
      api = Api.new(options)
      mysql.get_entries(last_id: state[:last_event_id], limit: options[:limit]) do |entries|
        logger.info { "Getting log messages from database..." }
        entries.each do |entry| 
          parser.extract_data_from_msg(entry['Message']) do |data|
            if data.size > 0
              data.each do |data_entry|
                if options[:accumulate]
                  cache.add(data_entry)
                  logger.debug {"Cached data: #{data_entry}"}
                else
                  url, status = api.send(data_entry)
                  verbose_parser_output(entry['ID'], data_entry, url, status)
                end
              end
              state[:last_event_id] = entry['ID']
              state[:match_count] += 1
            end
          end
        end
      end
      if options[:accumulate]
        resp_stats = {}
        api.send_sets(cache.data_sets, options[:concurrency]) do |url, status|
          logger.debug { "POST #{url} (#{status})" }
          resp_stats[status] = resp_stats[status].to_i + 1
        end
        logger.info { "Usage commited: #{resp_stats.map {|k,v| "#{v} x status #{k}" }.join(" : ")}" }
      end
    rescue SystemExit, Interrupt
      logger.error("Received an interrupt. Stopping the parser run.")
      state[:status] = STATUS[:interrupted] if state
    rescue => e
      logger.error "Aborting the parser run."
      logger.error e
      state[:status] = STATUS[:api_error] if state
    else
      state[:status] = STATUS[:ok]
    ensure
      begin
        if mysql && state
          state = STATUS[:unknown] if state[:status] == STATUS[:running]
          state[:run_time] = (Time.now - state[:started_at]).round(2)
          if state[:id] && !options[:simulate]
            mysql.write_parse_result(state)
          end
          log_parse_results(state)
          SmsLogparser::Loggster.instance.close
        end
      rescue => e
        logger.fatal e
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

    desc "clean-up [mode]", "Clean up the database - delete unused records"
    def clean_up(mode = "all")
      mysql = Mysql.new(options)
      case mode
      when "all"
        logger.info("Clean up parser table...")
        mysql.clean_up_parser_table
        logger.info("Clean up events table...")
        mysql.clean_up_events_table
        logger.info("All tables have been cleaned up.")
      when "events"
        logger.info("Clean up events table...")
        mysql.clean_up_events_table
        logger.info("Events table has been cleaned up.")
      when "parser"
        logger.info("Clean up parser table...")
        mysql.clean_up_parser_table
        logger.info("Parser table has been cleaned up.")
      else
        logger.warn("Mode '#{mode}' not allowed. Allowed modes are 'events', 'parser' or 'all'.")
      end
      SmsLogparser::Loggster.instance.close
    rescue => e
      logger.fatal e
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
      SmsLogparser::Loggster.instance.close
    rescue => e
      logger.fatal e
    end

    no_commands do
      def logger
        SmsLogparser::Loggster.instance.set_severity options[:severity]
        SmsLogparser::Loggster.instance.set_log_device options[:logfile]
      end

      def verbose_parser_output(entry_id, data, url, status)
        logger.debug {
          "Parsing data for #{entry_id} (#{data.map{|k,v| "#{k}=\"#{v || '-'}\""}.join(" ") || ''})"
        }
        logger.debug {"URL for entry #{entry_id}: #{url} (#{status})"}
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