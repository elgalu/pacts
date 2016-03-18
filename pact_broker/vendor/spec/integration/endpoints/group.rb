require 'spec_helper'

describe "/groups/{pacticipant-name}" do

  let(:app) { PactBroker::API }

  describe "GET" do
    before do
      ProviderStateBuilder.new.create_pact_with_hierarchy "Consumer", "1.2.3", "Provider"
      get "/groups/Consumer"
    end

    it "returns a success response" do
      expect(last_response.status).to eq 200
    end

    it "returns a body" do
      expect(last_response.body).to_not be_nil
    end
  end

end
