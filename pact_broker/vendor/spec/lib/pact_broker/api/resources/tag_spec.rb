require 'spec_helper'
require 'pact_broker/api/resources/tag'

module PactBroker
  module Api

    module Resources

      describe Tag do

        let(:tag) { double("PactBroker::Domain::Tag") }
        let(:tag_decorator) { instance_double("PactBroker::Api::Decorators::TagDecorator", :to_json => tag_json) }
        let(:tag_json) { {"some" => "tag"}.to_json }
        let(:tag_attributes) {
          {
            :pacticipant_name => "Condor",
            :pacticipant_version_number => "1.3.0",
            :tag_name => "prod"
          }
        }

        describe "GET" do
          before do
            allow(Services::TagService).to receive(:find).and_return(tag)
            allow(PactBroker::Api::Decorators::TagDecorator).to receive(:new).and_return(tag_decorator)
          end

          subject { get("/pacticipants/Condor/versions/1.3.0/tags/prod" ) }

          context "when the tag exists" do

            it "renders the tag" do
              subject
              expect(last_response.body).to eq tag_json
            end

            it "returns a success response" do
              subject
              expect(last_response).to be_successful
            end

          end

          context "when the tag does not exist" do
            let(:tag) { nil }

            it "returns a 404" do
              subject
              expect(last_response.status).to eq 404
            end
          end
        end

        describe "PUT" do

          let(:tag_url) { 'http://example.org/tag/url'}

          before do
            allow_any_instance_of(PactBroker::Api::Resources::Tag).to receive(:tag_url).and_return(tag_url)
            allow(Services::TagService).to receive(:find).and_return(tag)
            allow(PactBroker::Api::Decorators::TagDecorator).to receive(:new).and_return(tag_decorator)
          end

          subject { put("/pacticipants/Condor/versions/1.3.0/tags/prod", nil, "CONTENT_LENGTH" => "0", "CONTENT_TYPE" => "application/json") }

          it "returns a success response" do
            subject
            expect(last_response).to be_successful
          end

          context "when the tag already exists" do

            it "returns a 200" do
              subject
              expect(last_response.status).to be 200
            end

            it "renders the tag" do
              expect(tag_decorator).to receive(:to_json).with(base_url: "http://example.org")
              subject
              expect(last_response.body).to eq tag_json
            end

          end

          context "when the tag does not exist" do
            before do
              allow(Services::TagService).to receive(:find).and_return(nil)
              allow(Services::TagService).to receive(:create).and_return(tag)
            end


            it "creates the tag" do
              expect(Services::TagService).to receive(:create).with(tag_attributes)
              subject
            end

            it "returns a 201" do
              subject
              expect(last_response.status).to be 201
            end

            it "renders the tag" do
              expect(tag_decorator).to receive(:to_json).with(base_url: "http://example.org")
              subject
              expect(last_response.body).to eq tag_json
            end

          end


        end

      end

    end
  end
end
