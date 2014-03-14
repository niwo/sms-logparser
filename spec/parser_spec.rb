require 'spec_helper'

describe SmsLogparser::Parser do

  %w(f4v flv mp4 mp3 ts m3u8).each do |extension|
    it "matches #{extension} files" do
      SmsLogparser::Parser.match(
        "GET /content/2/719/54986/file.#{extension} HTTP/1.1\" 200 6741309 "
      ).wont_be_nil
    end
  end

  %w(jpg js css m4a docx).each do |extension|
    it "does not matche #{extension} files" do
      SmsLogparser::Parser.match(
        "GET /content/2/719/54986/file.#{extension} HTTP/1.1\" 200 6741309 "
      ).must_be_nil
    end
  end

  %w(200 206).each do |status|
    it "does match status code #{status}" do
      SmsLogparser::Parser.match(
        "GET /content/2/719/54986/file.mp4 HTTP/1.1\" #{status} 50000 "
      ).wont_be_nil
    end
  end

  %w(404 500 304).each do |status|
    it "does not match status code #{status}" do
      SmsLogparser::Parser.match(
        "GET /content/2/719/54986/file.mp4 HTTP/1.1\" #{status} 50000 "
      ).must_be_nil
    end
  end

  %w(contents public index CONTENT).each do |dir|
    it "does not match directories other than /content" do
      SmsLogparser::Parser.match(
        "GET /#{dir}/2/719/54986/file.mp4 HTTP/1.1\" 200 50000 "
      ).must_be_nil
    end
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
      SmsLogparser::Parser.get_traffic_type(mobile_agent).must_equal "TRAFFIC_MOBILE"
    end
  end

  it "should set visitor_type to VISITORS_MOBILE for index.m3u8 files" do
    SmsLogparser::Parser.get_visitor_type(
      "TRAFFIC_PODCAST", "index.m3u8"
    ).must_equal "VISITORS_MOBILE"
  end

  it "should NOT set visitor_type to VISITORS_MOBILE for TRAFFIC_MOBILE and .ts files" do
    SmsLogparser::Parser.get_visitor_type(
      "TRAFFIC_MOBILE", "file.ts"
    ).must_be_nil
  end

  it "should set visitor_type to VISITORS_MOBILE for TRAFFIC_MOBILE and file not .ts" do
    SmsLogparser::Parser.get_visitor_type(
      "TRAFFIC_MOBILE", "file.mp3"
    ).must_equal "VISITORS_MOBILE"
  end

  it "should set visitor_type to VISITORS_PODCAST for TRAFFIC_PODCAST" do
    SmsLogparser::Parser.get_visitor_type(
      "TRAFFIC_PODCAST", "file.mp4"
    ).must_equal "VISITORS_PODCAST"
  end

end