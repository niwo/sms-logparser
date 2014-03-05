require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/pride'

require 'sms-logparser'

module TestHelper

  @@mysql_db = 'syslog_test'
  @@mysql_user = 'root'
  @@sql_connection = nil

  def self.sms_logparser(options = {:mysql_db => @@mysql_db, :mysql_user => @@mysql_user})
    cli = SmsLogparser::Cli.new
    cli.options = options
    cli
  end

  def self.client
    @@sql_connection ||= Mysql2::Client.new(:host => 'localhost', :username => @@mysql_user)
  end

  def self.create_test_db
    self.drop_test_db
    self.client.query("CREATE DATABASE #{@@mysql_db}")
  end

  def self.drop_test_db
    self.client.query("DROP DATABASE IF EXISTS #{@@mysql_db}")
  end

  def self.create_sylog_db_table
    self.client.query(
      "CREATE TABLE IF NOT EXISTS\
        #{@@mysql_db}.SystemEvents(\
          ID INT PRIMARY KEY AUTO_INCREMENT,\
          FromHost varchar(128) DEFAULT '',\
          Message varchar(256) DEFAULT ''
      )"
    )
  end

  def self.insert_logs(host = "pcache", message = "", number_of_inserts = 1)
    values = ''
    number_of_inserts.times do
      values += "('#{host}', '#{message}'), "
    end
    self.client.query(
      "INSERT INTO #{@@mysql_db}.SystemEvents(FromHost, Message)\
        VALUES #{values.chomp(', ')}"
    )
  end

  def self.seed_db(number_of_inserts = 10)
    self.insert_logs(
      "blahost",
      "GET /boring/stuff/uninteresting - Firefox - 500 GET",
      number_of_inserts
    )
    self.insert_logs(
      "pcache",
      '- - [25/Feb/2014:17:28:57 +0100] \"GET /content/2/719/54986/simvid_1.f4v HTTP/1.1\" 200 6741309 \"-\" \"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.9; rv:27.0) Gecko/20100101 Firefox/27.0\"',
      number_of_inserts
    )
    self.insert_logs(
      "pcache",
      '- - [25/Feb/2014:17:28:57 +0100] \"GET /notcontent/2/719/54986/simvid_1.f4v HTTP/1.1\" 200 6741309 \"-\" \"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.9; rv:27.0) Gecko/20100101 Firefox/27.0\"',
      number_of_inserts
    )
  end
end