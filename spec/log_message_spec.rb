require 'spec_helper'

describe SmsLogparser::LogMessage do

  it "can extract the correct values from messages without arg string" do
    log_message = SmsLogparser::LogMessage.new('127.0.0.1 - - [13/Apr/2014:05:33:23 +0200] "GET /content/51/102/42481/simvid_1.mp4 HTTP/1.1" 206 7865189 "-" "iTunes/11.1.5 (Windows; Microsoft Windows 7 Home Premium Edition Service Pack 1 (Build 7601)) AppleWebKit/537.60.11"')
    log_message.customer_id.must_equal '51'
    log_message.author_id.must_equal '102'
    log_message.project_id.must_equal '42481'
    log_message.status.must_equal 206
    log_message.bytes.must_equal 7865189
    log_message.file.must_equal 'simvid_1.mp4'
    log_message.args.must_equal nil
    log_message.file_extname.must_equal '.mp4'
    log_message.user_agent.must_equal 'iTunes/11.1.5 (Windows; Microsoft Windows 7 Home Premium Edition Service Pack 1 (Build 7601)) AppleWebKit/537.60.11'
  end

  it "can extract the correct values from messages wit arg string" do
    log_message = SmsLogparser::LogMessage.new('- - [23/Apr/2014:17:36:33 +0200] "GET /content/51/52/42721/simvid_1_40.flv?position=22 HTTP/1.1" 206 100708 "http://blick.simplex.tv/NubesPlayer/player.swf" "Mozilla/5.0 (Windows NT 6.1; rv:28.0) Gecko/20100101 Firefox/28.0"')
    log_message.customer_id.must_equal '51'
    log_message.author_id.must_equal '52'
    log_message.project_id.must_equal '42721'
    log_message.status.must_equal 206
    log_message.bytes.must_equal 100708
    log_message.file.must_equal 'simvid_1_40.flv'
    log_message.args.must_equal 'position=22'
    log_message.file_extname.must_equal '.flv'
    log_message.user_agent.must_equal 'Mozilla/5.0 (Windows NT 6.1; rv:28.0) Gecko/20100101 Firefox/28.0'
  end

  it "can extract the correct values from messages without files" do
    log_message = SmsLogparser::LogMessage.new('- - [23/Apr/2014:17:47:32 +0200] "GET /content/51/52/42624/ HTTP/1.1" 200 1181 "-" "Googlebot-Video/1.0"')
    log_message.customer_id.must_equal '51'
    log_message.author_id.must_equal '52'
    log_message.project_id.must_equal '42624'
    log_message.status.must_equal 200
    log_message.bytes.must_equal 1181
    log_message.file.must_equal nil
    log_message.args.must_equal nil
    log_message.file_extname.must_equal nil
    log_message.user_agent.must_equal 'Googlebot-Video/1.0'
  end

  it "does not fail on double slashes" do
    log_message = SmsLogparser::LogMessage.new('- - [23/Apr/2014:23:01:24 +0200] "GET /content/244/245/42601//player_logo.jpg?0.19035581778734922 HTTP/1.1" 200 21671 "http://blick.simplex.tv/content/244/245/42601/" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/34.0.1847.116 Safari/537.36"')
    log_message.customer_id.must_equal nil
    log_message.author_id.must_equal nil
    log_message.project_id.must_equal nil
    log_message.status.must_equal nil
    log_message.bytes.must_equal nil
    log_message.file.must_equal nil
    log_message.args.must_equal nil
    log_message.file_extname.must_equal nil
    log_message.user_agent.must_equal nil
    #log_message.status.must_equal 200
    #log_message.bytes.must_equal 1181
    #log_message.file.must_equal 'player_logo.jpg'
    #log_message.args.must_equal '0.19035581778734922'
    #log_message.file_extname.must_equal 'jpg'
    #log_message.user_agent.must_equal 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/34.0.1847.116 Safari/537.36'
  end

end