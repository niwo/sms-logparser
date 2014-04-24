require 'spec_helper'

describe SmsLogparser::Parser do

  it "count index.m3u8 with status 200 and user agent iPhone as mobile visit" do
    message = '- - [22/Apr/2014:17:44:17 +0200] "GET /content/51/52/42701/index.m3u8 HTTP/1.1" 200 319009 "-" "AppleCoreMedia/1.0.0.11D167 (iPhone; U; CPU OS 7_1 like Mac OS X; de_de)"'
    data = SmsLogparser::Parser.extract_data_from_msg(message)
    data[1][:customer_id].must_equal "51"
    data[1][:author_id].must_equal "52"
    data[1][:project_id].must_equal "42701"
    data[1][:type].must_equal 'VISITORS_MOBILE'
    data[1][:value].must_equal 1
  end

  it "count *.flv with status 200 and user agent Android as mobile visit" do
    message = ' - - [22/Apr/2014:17:44:27 +0200] "GET /content/51/52/42709/simvid_1_40.flv HTTP/1.1" 200 9625900 "http://blick.simplex.tv/NubesPlayer/index.html?cID=51&aID=52&pID=42709&autostart=false&themeColor=d6081c&embed=1&configUrl=http://f.blick.ch/resources/61786/ver1-0/js/xtendxIframeStatsSmartphone.js?adtechID=3522740&language=de&quality=40&hideHD=true&progressiveDownload=true" "Mozilla/5.0 (Linux; Android 4.4.2; C6903 Build/14.3.A.0.757) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/34.0.1847.114 Mobile Safari/537.36"'
    data = SmsLogparser::Parser.extract_data_from_msg(message)
    data[1][:customer_id].must_equal "51"
    data[1][:author_id].must_equal "52"
    data[1][:project_id].must_equal "42709"
    data[1][:type].must_equal 'VISITORS_MOBILE'
    data[1][:value].must_equal 1
  end

  it "count *.mp4 with status 200 and user agent Android as mobile visit" do
    message = '- - [22/Apr/2014:17:44:21 +0200] "GET /content/51/52/42701/simvid_1.mp4 HTTP/1.1" 200 2644715 "-" "Samsung GT-I9505 stagefright/1.2 (Linux;Android 4.4.2)"'
    data = SmsLogparser::Parser.extract_data_from_msg(message)
    data[1][:customer_id].must_equal "51"
    data[1][:author_id].must_equal "52"
    data[1][:project_id].must_equal "42701"
    data[1][:type].must_equal 'VISITORS_MOBILE'
    data[1][:value].must_equal 1
  end

  it "count *.flv with status 200 and user agent Firefox on Windows as webcast visit" do
    message = '- - [22/Apr/2014:18:00:50 +0200] "GET /content/51/52/42431/simvid_1_40.flv HTTP/1.1" 200 6742274 "http://blick.simplex.tv/NubesPlayer/player.swf" "Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko"'
    data = SmsLogparser::Parser.extract_data_from_msg(message)
    data[1][:customer_id].must_equal "51"
    data[1][:author_id].must_equal "52"
    data[1][:project_id].must_equal "42431"
    data[1][:type].must_equal 'VISITORS_WEBCAST'
    data[1][:value].must_equal 1
  end

  it "count traffic with status 206 and a argumenst string and user agent Firefox on Windows as webcast visit" do
    message = '- - [23/Apr/2014:17:36:33 +0200] "GET /content/51/52/42721/simvid_1_40.flv?position=22 HTTP/1.1" 206 100708 "http://blick.simplex.tv/NubesPlayer/player.swf" "Mozilla/5.0 (Windows NT 6.1; rv:28.0) Gecko/20100101 Firefox/28.0"'
    data = SmsLogparser::Parser.extract_data_from_msg(message)
    data.first[:customer_id].must_equal "51"
    data.first[:author_id].must_equal "52"
    data.first[:project_id].must_equal "42721"
    data.first[:type].must_equal 'TRAFFIC_WEBCAST'
    data.first[:value].must_equal 100708
  end

  it "count traffic with status 200 and no file from bot as webcast visit" do
    message = '- - [23/Apr/2014:17:47:32 +0200] "GET /content/51/52/42624/ HTTP/1.1" 200 1181 "-" "Googlebot-Video/1.0"'
    data = SmsLogparser::Parser.extract_data_from_msg(message)
    data.size.must_equal 1
    data.first[:customer_id].must_equal "51"
    data.first[:author_id].must_equal "52"
    data.first[:project_id].must_equal "42624"
    data.first[:type].must_equal 'TRAFFIC_WEBCAST'
    data.first[:value].must_equal 1181
  end

  it "do not count *.css with status 200 as visit" do
    message = '- - [22/Apr/2014:18:00:50 +0200] "GET /content/51/52/42431/application.css HTTP/1.1" 200 192 "http://blick.simplex.tv/NubesPlayer/player.swf" "Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko"'
    data = SmsLogparser::Parser.extract_data_from_msg(message)
    data.size.must_equal 1
  end

  it "do not count status 206 as visit" do
    message = '- - [22/Apr/2014:18:00:50 +0200] "GET /content/51/52/42431/simvid_1_40.flv HTTP/1.1" 206 19289 "http://blick.simplex.tv/NubesPlayer/player.swf" "Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko"'
    data = SmsLogparser::Parser.extract_data_from_msg(message)
    data.size.must_equal 1
  end

end