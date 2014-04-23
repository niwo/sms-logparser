require 'spec_helper'

describe SmsLogparser::Parser do

  %w(f4v flv mp4 mp3 ts m3u8 jpg js css m4a png sid).each do |extension|
    it "matches #{extension} files" do
      SmsLogparser::Parser.match?(
        "GET /content/2/719/54986/file.#{extension} HTTP/1.1\" 200 6741309 "
      ).must_equal true
    end
  end

  %w(200 206).each do |status|
    it "does match status code #{status}" do
      SmsLogparser::Parser.match?(
        "GET /content/2/719/54986/file.mp4 HTTP/1.1\" #{status} 50000 "
      ).must_equal true
    end
  end

  %w(404 500 304).each do |status|
    it "does not match status code #{status}" do
      SmsLogparser::Parser.match?(
        "GET /content/2/719/54986/file.mp4 HTTP/1.1\" #{status} 50000 "
      ).must_equal false
    end
  end

  %w(contents public index assets).each do |dir|
    it "does not match directories other than /content" do
      SmsLogparser::Parser.match?(
        "GET /#{dir}/2/719/54986/file.mp4 HTTP/1.1\" 200 50000 "
      ).must_equal false
    end
  end

  it "does not match for 'detect.mp4' files" do
    SmsLogparser::Parser.match?(
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
      SmsLogparser::Parser.get_type(mobile_agent).must_equal "MOBILE"
    end
  end

  [
    '127.0.0.1 - - [13/Apr/2014:05:33:23 +0200] "GET /content/51/52/42481/simvid_1.mp4 HTTP/1.1" 206 7865189 "-" "iTunes/11.1.5 (Windows; Microsoft Windows 7 Home Premium Edition Service Pack 1 (Build 7601)) AppleWebKit/537.60.11"'
  ].each do |podcast_agent|
    it "traffic type for mobile user agents is TRAFFIC_PODCAST (#{podcast_agent})" do
      SmsLogparser::Parser.get_type(podcast_agent).must_equal "PODCAST"
    end
  end

  it "count index.m3u8 with status 200 and user agent iPhone as mobile visit" do
    message = '- - [22/Apr/2014:17:44:17 +0200] "GET /content/51/52/42701/index.m3u8 HTTP/1.1" 200 319 "-" "AppleCoreMedia/1.0.0.11D167 (iPhone; U; CPU OS 7_1 like Mac OS X; de_de)"'
    data = SmsLogparser::Parser.new.extract_data_from_msg(message)
    data[1][:customer_id].must_equal "51"
    data[1][:author_id].must_equal "52"
    data[1][:project_id].must_equal "42701"
    data[1][:type].must_equal 'VISITORS_MOBILE'
    data[1][:value].must_equal 1
  end

  it "count *.flv with status 200 and user agent Android as mobile visit" do
    message = ' - - [22/Apr/2014:17:44:27 +0200] "GET /content/51/52/42709/simvid_1_40.flv HTTP/1.1" 200 96259 "http://blick.simplex.tv/NubesPlayer/index.html?cID=51&aID=52&pID=42709&autostart=false&themeColor=d6081c&embed=1&configUrl=http://f.blick.ch/resources/61786/ver1-0/js/xtendxIframeStatsSmartphone.js?adtechID=3522740&language=de&quality=40&hideHD=true&progressiveDownload=true" "Mozilla/5.0 (Linux; Android 4.4.2; C6903 Build/14.3.A.0.757) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/34.0.1847.114 Mobile Safari/537.36"'
    data = SmsLogparser::Parser.new.extract_data_from_msg(message)
    data[1][:customer_id].must_equal "51"
    data[1][:author_id].must_equal "52"
    data[1][:project_id].must_equal "42709"
    data[1][:type].must_equal 'VISITORS_MOBILE'
    data[1][:value].must_equal 1
  end

  it "count *.mp4 with status 200 and user agent Android as mobile visit" do
    message = '- - [22/Apr/2014:17:44:21 +0200] "GET /content/51/52/42701/simvid_1.mp4 HTTP/1.1" 200 2644715 "-" "Samsung GT-I9505 stagefright/1.2 (Linux;Android 4.4.2)"'
    data = SmsLogparser::Parser.new.extract_data_from_msg(message)
    data[1][:customer_id].must_equal "51"
    data[1][:author_id].must_equal "52"
    data[1][:project_id].must_equal "42701"
    data[1][:type].must_equal 'VISITORS_MOBILE'
    data[1][:value].must_equal 1
  end

  it "count *.flv with status 200 and user agent Firefox on Windows as webcast visit" do
    message = '- - [22/Apr/2014:18:00:50 +0200] "GET /content/51/52/42431/simvid_1_40.flv HTTP/1.1" 200 6742274 "http://blick.simplex.tv/NubesPlayer/player.swf" "Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko"'
    data = SmsLogparser::Parser.new.extract_data_from_msg(message)
    data[1][:customer_id].must_equal "51"
    data[1][:author_id].must_equal "52"
    data[1][:project_id].must_equal "42431"
    data[1][:type].must_equal 'VISITORS_WEBCAST'
    data[1][:value].must_equal 1
  end

  it "count traffic with status 206 and a argumenst string and user agent Firefox on Windows as webcast visit" do
    message = '- - [23/Apr/2014:17:36:33 +0200] "GET /content/51/52/42721/simvid_1_40.flv?position=22 HTTP/1.1" 206 100708 "http://blick.simplex.tv/NubesPlayer/player.swf" "Mozilla/5.0 (Windows NT 6.1; rv:28.0) Gecko/20100101 Firefox/28.0"'
    data = SmsLogparser::Parser.new.extract_data_from_msg(message)
    data.first[:customer_id].must_equal "51"
    data.first[:author_id].must_equal "52"
    data.first[:project_id].must_equal "42721"
    data.first[:type].must_equal 'TRAFFIC_WEBCAST'
    data.first[:value].must_equal 100708
  end

  it "do not count *.css with status 200 as visit" do
    message = '- - [22/Apr/2014:18:00:50 +0200] "GET /content/51/52/42431/application.css HTTP/1.1" 200 192 "http://blick.simplex.tv/NubesPlayer/player.swf" "Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko"'
    data = SmsLogparser::Parser.new.extract_data_from_msg(message)
    data.size.must_equal 1
  end

  it "do not count status 206 as visit" do
    message = '- - [22/Apr/2014:18:00:50 +0200] "GET /content/51/52/42431/simvid_1_40.flv HTTP/1.1" 206 19289 "http://blick.simplex.tv/NubesPlayer/player.swf" "Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko"'
    data = SmsLogparser::Parser.new.extract_data_from_msg(message)
    data.size.must_equal 1
  end

end