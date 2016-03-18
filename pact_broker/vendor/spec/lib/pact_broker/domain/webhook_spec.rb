require 'spec_helper'
require 'pact_broker/domain/webhook'

module PactBroker

  module Domain

    describe Webhook do

      let(:consumer) { Pacticipant.new(name: 'Consumer')}
      let(:provider) { Pacticipant.new(name: 'Provider')}
      let(:request) { instance_double(PactBroker::Domain::WebhookRequest, execute: nil)}
      subject { Webhook.new(request: request, consumer: consumer, provider: provider,) }

      describe "description" do
        it "returns a description of the webhook" do
          expect(subject.description).to eq "A webhook for the pact between Consumer and Provider"
        end
      end

      describe "execute" do

        it "executes the request" do
          expect(request).to receive(:execute)
          subject.execute
        end

        it "logs before and after" do
          expect(PactBroker.logger).to receive(:info).with(/Executing/)
          subject.execute
        end

      end
    end

  end

end
