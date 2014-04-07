require 'spec_helper'

describe SmsLogparser::Api do

  before do
    @api = SmsLogparser::Api.new(
      simulate: true,
      api_base_url: "http://localhost/creator/rest/"
    )
  end

  it "sends the correct information to the api" do
    data = {
      :customer_id => 1,
      :author_id => 2,
      :project_id => 3,
      :file =>  'myfile.mp4',
      :bytes => 128,
      :user_agent => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_2) AppleWebKit/537.36 (KHTML, like Gecko)",
      :traffic_type => 'TRAFFIC_WEBCAST',
      :visitor_type => 'VISITORS_WEBCAST'
    }
    requests = @api.send(data)
    requests.size.must_equal 2
    requests[0][:uri].must_match /\/1\/2\/3\/TRAFFIC_WEBCAST\/128$/
    requests[1][:uri].must_match /\/1\/2\/3\/VISITORS_WEBCAST\/1$/
  end

  it "does not send traffic for m3u8 files" do
    data = {
      :customer_id => 100,
      :author_id => 200,
      :project_id => 300,
      :file =>  'myfile.m3u8',
      :bytes => 512,
      :user_agent => 'Mozilla/5.0 (Android; Mobile; rv:13.0) Gecko/13.0 Firefox/13.0',
      :traffic_type => 'TRAFFIC_MOBILE',
      :visitor_type => 'VISITORS_MOBILE'
    }
    requests = @api.send(data)
    requests.size.must_equal 1
    requests[0][:uri].must_match /\/100\/200\/300\/VISITORS_MOBILE\/1$/
  end

  it "does not send visitor info if no visitor_type" do
    data = {
      :customer_id => 101,
      :author_id => 202,
      :project_id => 303,
      :file =>  'myfile.mp4',
      :bytes => 48,
      :user_agent => 'Mozilla/5.0 (Android; Mobile; rv:13.0) Gecko/13.0 Firefox/13.0',
      :traffic_type => 'TRAFFIC_MOBILE',
    }
    requests = @api.send(data)
    requests.size.must_equal 1
    requests[0][:uri].must_match /\/101\/202\/303\/TRAFFIC_MOBILE\/48$/
  end

end