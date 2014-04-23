require 'spec_helper'

describe SmsLogparser::Api do

  before do
    @api = SmsLogparser::Api.new(
      simulate: true,
      api_base_url: "http://localhost/creator/rest/"
    )
  end

  it "builds the correct path for TRAFFIC data" do
    data = {
      :customer_id => 1,
      :author_id => 2,
      :project_id => 3,
      :value => 128,
      :type => 'TRAFFIC_WEBCAST',
    }
    @api.data_to_path(data).must_match /\/1\/2\/3\/TRAFFIC_WEBCAST\/128$/
  end

  it "builds the correct path for VISITOR data" do
    data = {
      customer_id: 101,
      author_id: 202,
      project_id: 303,
      type: 'TRAFFIC_MOBILE',
      value: 48
    }
    @api.data_to_path(data).must_match /\/101\/202\/303\/TRAFFIC_MOBILE\/48$/
  end

end