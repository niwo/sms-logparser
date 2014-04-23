require 'spec_helper'

describe SmsLogparser::LogMessage do

  it "can extract the correct values from messages" do
    log_message = SmsLogparser::LogMessage.new('127.0.0.1 - - [13/Apr/2014:05:33:23 +0200] "GET /content/51/102/42481/simvid_1.mp4 HTTP/1.1" 206 7865189 "-" "iTunes/11.1.5 (Windows; Microsoft Windows 7 Home Premium Edition Service Pack 1 (Build 7601)) AppleWebKit/537.60.11"')
    log_message.customer_id.must_equal '51'
    log_message.author_id.must_equal '102'
    log_message.project_id.must_equal '42481'
    log_message.status.must_equal '206'
    log_message.bytes.must_equal 7865189
    log_message.file.must_equal 'simvid_1.mp4'
    log_message.file_extname.must_equal '.mp4'
    log_message.user_agent.must_equal 'iTunes/11.1.5 (Windows; Microsoft Windows 7 Home Premium Edition Service Pack 1 (Build 7601)) AppleWebKit/537.60.11'
  end

end