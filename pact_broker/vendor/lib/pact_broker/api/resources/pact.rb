require 'cgi'
require 'pact_broker/api/resources/base_resource'
require 'pact_broker/api/resources/pacticipant_resource_methods'
require 'pact_broker/api/decorators/pact_decorator'
require 'pact_broker/json'
require 'pact_broker/pacts/pact_params'
require 'pact_broker/api/contracts/put_pact_params_contract'

module PactBroker

  module Api
    module Resources

      class Pact < BaseResource

        include PacticipantResourceMethods

        def content_types_provided
          [["application/json", :to_json]]
        end

        def content_types_accepted
          [["application/json", :from_json]]
        end

        def allowed_methods
          ["GET", "PUT", "DELETE"]
        end

        def is_conflict?
          potential_duplicate_pacticipants?(pact_params.pacticipant_names)
        end

        def malformed_request?
          if request.put?
            return invalid_json? ||
              contract_validation_errors?(Contracts::PutPactParamsContract.new(pact_params))
          else
            false
          end
        end

        def resource_exists?
          pact
        end

        def from_json
          response_code = pact ? 200 : 201
          @pact = pact_service.create_or_update_pact(pact_params)
          response.body = to_json
          response_code
        end

        def to_json
          PactBroker::Api::Decorators::PactDecorator.new(pact).to_json(base_url: base_url)
        end

        def delete_resource
          pact_service.delete(pact_params)
          true
        end

        private

        def pact
          @pact ||= pact_service.find_pact(pact_params)
        end

        def pact_params
          @pact_params ||= PactBroker::Pacts::PactParams.from_request request, path_info
        end

      end
    end
  end
end