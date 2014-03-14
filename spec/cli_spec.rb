require 'spec_helper'

describe SmsLogparser::Cli do
  before do
    TestHelper.create_test_db
    TestHelper.create_sylog_db_table
  end

  after do
    TestHelper.drop_test_db
  end

  it "can create the parser_runs database table" do
    out, err = capture_io do
      TestHelper.sms_logparser.setup
    end
    out.must_match /OK/
  end

  it "can parse a log database and find matches" do
    TestHelper.seed_db(10)
    parser = TestHelper.sms_logparser
    parser.options[:api_base_path] = 'http://devnull-as-a-service.com/dev/null/'
    out, err = capture_io do
      TestHelper.sms_logparser.setup
      parser.parse  
    end
    out.must_match /\s+10$/
  end

  it "skips over already parsed logs" do
    TestHelper.seed_db(1)
    parser = TestHelper.sms_logparser
    parser.options[:api_base_path] = 'http://devnull-as-a-service.com/dev/null/'
    out, err = capture_io do
      TestHelper.sms_logparser.setup
      parser.parse
      parser.parse  
    end
    out.must_match /\s+0$/
  end

  it "lists parser runs" do
    TestHelper.seed_db(1)
    parser = TestHelper.sms_logparser
    parser.options[:api_base_path] = 'http://devnull-as-a-service.com/dev/null/'
    out, err = capture_io do
      TestHelper.sms_logparser.setup
      parser.parse
      parser.last_runs 
    end
    assert_equal(err, "")
  end
end
