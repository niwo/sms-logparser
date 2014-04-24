require 'spec_helper'

describe SmsLogparser::LogMessage do

    %w(f4v flv mp4 mp3 ts m3u8 jpg js css m4a png sid).each do |extension|
    it "matches #{extension} files" do
      SmsLogparser::LogMessage.match?(
        "GET /content/2/719/54986/file.#{extension} HTTP/1.1\" 200 6741309 "
      ).must_equal true
    end
  end

  %w(200 206).each do |status|
    it "does match status code #{status}" do
      SmsLogparser::LogMessage.match?(
        "GET /content/2/719/54986/file.mp4 HTTP/1.1\" #{status} 50000 "
      ).must_equal true
    end
  end

  %w(404 500 304).each do |status|
    it "does not match status code #{status}" do
      SmsLogparser::LogMessage.match?(
        "GET /content/2/719/54986/file.mp4 HTTP/1.1\" #{status} 50000 "
      ).must_equal false
    end
  end

  %w(contents public index assets).each do |dir|
    it "does not match directories other than /content" do
      SmsLogparser::LogMessage.match?(
        "GET /#{dir}/2/719/54986/file.mp4 HTTP/1.1\" 200 50000 "
      ).must_equal false
    end
  end

  it "does not match for 'detect.mp4' files" do
    SmsLogparser::LogMessage.match?(
      "GET /content/2/719/54986/detect.mp4 HTTP/1.1\" 200 128 "
    ).must_equal false
  end

  [
    "Mozilla/5.0(iPad; U; CPU iPhone OS 3_2 like Mac OS X; en-us) AppleWebKit/531.21.10 (KHTML, like Gecko) Version/4.0.4 Mobile/7B314 Safari/531.21.10",
    "Mozilla/5.0 (Android; Mobile; rv:13.0) Gecko/13.0 Firefox/13.0",
    "Opera/9.80 (Android 2.3.3; Linux; Opera Mobi/ADR-1111101157; U; es-ES) Presto/2.9.201 Version/11.50",
    "Mozilla/5.0 (Linux; Android 4.4.2); Nexus 5 Build/KOT49H) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/33.0.1750.117 Mobile Safari/537.36 OPR/20.0.1396.72047",
    "Mozilla/5.0 (compatible; MSIE 9.0; Windows Phone OS 7.5; Trident/5.0; IEMobile/9.0)",
    "Mozilla/5.0 (iPhone; U; CPU iPhone OS 5_1_1 like Mac OS X; en) AppleWebKit/534.46.0 (KHTML, like Gecko) CriOS/19.0.1084.60 Mobile/9B206 Safari/7534.48.3"
  ].each do |mobile_agent|
    it "traffic type for mobile user agents is TRAFFIC_MOBILE (#{mobile_agent})" do
      SmsLogparser::LogMessage.get_type(mobile_agent).must_equal "MOBILE"
    end
  end

  [
    '127.0.0.1 - - [13/Apr/2014:05:33:23 +0200] "GET /content/51/52/42481/simvid_1.mp4 HTTP/1.1" 206 7865189 "-" "iTunes/11.1.5 (Windows; Microsoft Windows 7 Home Premium Edition Service Pack 1 (Build 7601)) AppleWebKit/537.60.11"'
  ].each do |podcast_agent|
    it "traffic type for mobile user agents is TRAFFIC_PODCAST (#{podcast_agent})" do
      SmsLogparser::LogMessage.get_type(podcast_agent).must_equal "PODCAST"
    end
  end

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
    log_message.customer_id.must_equal '244'
    log_message.author_id.must_equal '245'
    log_message.project_id.must_equal '42601'
    log_message.status.must_equal 200
    log_message.bytes.must_equal 21671
    log_message.file.must_equal 'player_logo.jpg'
    log_message.args.must_equal '0.19035581778734922'
    log_message.file_extname.must_equal '.jpg'
    log_message.user_agent.must_equal 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/34.0.1847.116 Safari/537.36'
  end

end