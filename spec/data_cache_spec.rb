require 'spec_helper'

describe SmsLogparser::DataCache do

  before do
    @cache = SmsLogparser::DataCache.new
  end

  it "returns correct totals from cache" do
    @cache.add(customer_id: 101, author_id: 202, project_id: 303, type: 'TRAFFIC_MOBILE', value: 10)
    @cache.add(customer_id: 101, author_id: 202, project_id: 303, type: 'TRAFFIC_MOBILE', value: 400)
    @cache.add(customer_id: 101, author_id: 202, project_id: 303, type: 'TRAFFIC_MOBILE', value: 1000)

    @cache.add(customer_id: 101, author_id: 202, project_id: 303, type: 'TRAFFIC_WEBCAST', value: 1000)

    1000.times do 
      @cache.add(customer_id: 101, author_id: 300, project_id: 303, type: 'VISIT_WEBCAST', value: 1)
    end

    @cache.add(customer_id: 1, author_id: 10, project_id: 600, type: 'TRAFFIC_MOBILE', value: 500)

    @cache.data_sets.must_include(customer_id: "101", author_id: "202", project_id: "303", type: "TRAFFIC_MOBILE", value: 1410)
    @cache.data_sets.must_include(customer_id: "101", author_id: "202", project_id: "303", type: "TRAFFIC_WEBCAST", value: 1000)
    @cache.data_sets.must_include(customer_id: "101", author_id: "300", project_id: "303", type: "VISIT_WEBCAST", value: 1000)
    @cache.data_sets.must_include(customer_id: "1", author_id: "10", project_id: "600", type: "TRAFFIC_MOBILE", value: 500)
  end

end