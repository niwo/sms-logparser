require 'spec_helper'

describe SmsLogparser::Cli do
  before do
    TestHelper.create_test_db
    TestHelper.create_sylog_db_table
    stub_request(:post, /.*locahost.*/).
      with(headers: {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
      to_return(status: 200, body: "stubbed response", headers: {})
  end

  after do
    TestHelper.drop_test_db
  end

  it "can create the parser_runs database table" do
    parser = TestHelper.sms_logparser
    parser.options[:force] = true
    out, err = capture_io do
      parser.setup
    end
    out.must_match /OK.*/
  end

  it "can parse a log database and find matches" do
    TestHelper.seed_db(10)
    parser = TestHelper.sms_logparser
    parser.options[:simulate] = true
    #parser.options[:api_base_url] = "http://localhost/creator/rest/"
    out, err = capture_io do
      parser.setup
      parser.parse  
    end
    out.must_match /\s+10$/
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

    out, err = capture_io do
      parser.setup
      parser.parse
      parser.history 
    end
    err.must_equal ""
  end
end
