require 'spec_helper'

LOGFILE = '/tmp/sms-logparser.log'

describe SmsLogparser::Cli do
  before do
    TestHelper.create_test_db
    TestHelper.create_sylog_db_table
  end

  after do
    TestHelper.drop_test_db
    FileUtils.rm(LOGFILE) if File.exists?(LOGFILE)
  end

  it "can create the parser_runs database table" do
    parser = TestHelper.sms_logparser
    parser.options[:force] = true
    parser.options[:logfile] = LOGFILE
    parser.setup
    IO.read(LOGFILE).must_include 'Created database table.'
  end

  it "can parse a log database and find matches" do
    TestHelper.seed_db(10)
    parser = TestHelper.sms_logparser
    parser.options[:simulate] = true
    parser.options[:logfile] = LOGFILE
    #parser.options[:api_base_url] = "http://localhost/creator/rest/"
    parser.setup
    parser.parse
    IO.read(LOGFILE).must_include 'match_count="10"'
  end

  # it "skips over already parsed logs" do
  #   TestHelper.seed_db(1)
  #   parser = TestHelper.sms_logparser
  #   parser.options[:simulate] = true
  #   out, err = capture_io do
  #     TestHelper.sms_logparser.setup
  #     parser.parse
  #     parser.parse  
  #   end
  #   out.must_match /\s+0$/
  # end

  it "can show the parser history" do
    TestHelper.seed_db(1)
    parser = TestHelper.sms_logparser
    parser.options[:simulate] = true
    parser.options[:force] = true
    parser.options[:logfile] = LOGFILE
    parser.setup
    parser.parse

    out, err = capture_io do
      parser.history 
    end
    err.must_equal ""
  end
end
