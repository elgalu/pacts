module PactBroker
  module Api
    module PactBrokerUrls

      extend self

      def pacticipants_url base_url
        "#{base_url}/pacticipants"
      end

      def pacticipant_url base_url, pacticipant
        "#{pacticipants_url(base_url)}/#{url_encode(pacticipant.name)}"
      end

      def latest_version_url base_url, pacticipant
        "#{pacticipant_url(base_url, pacticipant)}/versions/latest"
      end

      def versions_url base_url, pacticipant
        "#{pacticipant_url(base_url, pacticipant)}/versions"
      end

      def version_url base_url, version
        "#{pacticipant_url(base_url, version.pacticipant)}/versions/#{version.number}"
      end

      def pact_url base_url, pact
        "#{pactigration_base_url(base_url, pact)}/version/#{pact.consumer_version_number}"
      end

      def pact_url_from_params base_url, params
        [ base_url, 'pacts',
          'provider', url_encode(params[:provider_name]),
          'consumer', url_encode(params[:consumer_name]),
          'version', url_encode(params[:consumer_version_number]) ].join('/')
      end

      def latest_pact_url base_url, pact
        "#{pactigration_base_url(base_url, pact)}/latest"
      end

      def latest_pacts_url base_url
        "#{base_url}/pacts/latest"
      end

      def pact_versions_url consumer_name, provider_name, base_url
        "#{base_url}/pacts/provider/#{url_encode(provider_name)}/consumer/#{url_encode(consumer_name)}/versions"
      end

      def previous_distinct_diff_url pact, base_url
        pact_url(base_url, pact) + "/diff/previous-distinct"
      end

      def previous_distinct_pact_version_url pact, base_url
        pact_url(base_url, pact) + "/previous-distinct"
      end

      def tags_url base_url, version
        "#{version_url(base_url, version)}/tags"
      end

      def tag_url base_url, tag
        "#{tags_url(base_url, tag.version)}/#{tag.name}"
      end

      def webhooks_url base_url
        "#{base_url}/webhooks"
      end

      def webhook_url uuid, base_url
        "#{base_url}/webhooks/#{uuid}"
      end

      def webhook_execution_url webhook, base_url
        "#{base_url}/webhooks/#{webhook.uuid}/execute"
      end

      def webhooks_for_pact_url consumer, provider, base_url
        "#{base_url}/webhooks/provider/#{url_encode(provider.name)}/consumer/#{url_encode(consumer.name)}"
      end

      def hal_browser_url target_url
        "/hal-browser/browser.html#" + target_url
      end

      def url_encode param
        ERB::Util.url_encode param
      end

      private

      def representable_pact pact
        Decorators::RepresentablePact === pact ? pact : Decorators::RepresentablePact.new(pact)
      end

      def pactigration_base_url base_url, pact
        "#{base_url}/pacts/provider/#{url_encode(pact.provider.name)}/consumer/#{url_encode(pact.consumer.name)}"
      end
    end
  end
end