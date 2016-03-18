require_relative 'base_decorator'
require_relative 'embedded_version_decorator'
require_relative 'latest_pact_decorator'
require_relative 'representable_pact'

module PactBroker

  module Api

    module Decorators

      class PactCollectionDecorator < BaseDecorator
        include Roar::JSON::HAL
        include PactBroker::Api::PactBrokerUrls

        collection :pacts, exec_context: :decorator, :class => PactBroker::Domain::Pact, :extend => PactBroker::Api::Decorators::LatestPactDecorator

        def pacts
          represented.collect{ | pact | create_representable_pact(pact) }
        end

        def create_representable_pact pact
          PactBroker::Api::Decorators::RepresentablePact.new(pact)
        end

        link :self do | options |
          latest_pacts_url(options[:base_url])
        end

        # This is the LATEST pact URL
        links :pacts do | options |
          represented.collect do | pact |
            {
              :href => latest_pact_url(options[:base_url], pact),
              :name => "Latest pact between #{pact.consumer.name} and #{pact.provider.name}",
              :title => "Pact"
            }
          end
        end

      end
    end
  end
end