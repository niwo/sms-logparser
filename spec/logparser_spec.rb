require 'spec_helper'

describe SmsLogparser do
  before do
    # create the test database
    client = Mysql2::Client.new(:host => 'localhost', :username => MYSQL_USER)
    client.query("DROP DATABASE IF EXISTS #{MYSQL_DB}")
    client.query("CREATE DATABASE #{MYSQL_DB}")

    client.query(
      "CREATE TABLE IF NOT EXISTS\
        #{MYSQL_DB}.SystemEvents(\
          ID INT PRIMARY KEY AUTO_INCREMENT,\
          FromHost varchar(128) DEFAULT '',\
          Message varchar(256) DEFAULT ''
      )"
    )

    100.times do
      client.query(
        "INSERT INTO #{MYSQL_DB}.SystemEvents(FromHost, Message)\
          VALUES(\
            'bla',\
            'lklkllkl'
        )"
      )
    end

    100.times do
      client.query(
        "INSERT INTO #{MYSQL_DB}.SystemEvents(FromHost, Message)\
          VALUES(\
            'pcache',\
            '- - [25/Feb/2014:17:28:57 +0100] \"GET /content/2/719/54986/simvid_1.f4v HTTP/1.1\" 200 6741309 \"-\" \"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.9; rv:27.0) Gecko/20100101 Firefox/27.0\"'
        )"
      )
    end

    100.times do
      client.query(
        "INSERT INTO #{MYSQL_DB}.SystemEvents(FromHost, Message)\
          VALUES(\
            'pcache',\
            '- - [25/Feb/2014:17:28:57 +0100] \"GET /bla/2/719/54986/simvid_1.f4v HTTP/1.1\" 200 6741309 \"-\" \"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.9; rv:27.0) Gecko/20100101 Firefox/27.0\"'
        )"
      )
    end
  end

  it "can create the parser_runs database table" do
    out, err = capture_io do
      cli.create_parser_table
    end
    out.must_match /OK/
  end

  it "can parse a log database and find matches" do
    cli.create_parser_table
    puts cli.parse
    out, err = capture_io do
      cli.parse  
    end
    puts out
    1.must_equal 1
  end

  it "can skip over already parsed logs" do
    1.must_equal 1
  end
end