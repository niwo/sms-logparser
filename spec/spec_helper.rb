require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/pride'

require 'sms-logparser'

MYSQL_DB = 'syslog_test'
MYSQL_USER = 'root'

def cli
  cli = SmsLogparser::Cli.new
  cli.options = {:mysql_db => MYSQL_DB, :mysql_user => MYSQL_USER}
  cli
end