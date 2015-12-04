require 'http'
require 'active_support/cache'
require 'new_relic/agent'

require './lib/validations'
require './lib/conf'
require './lib/rack-oauth2-bearer'

module Rack::OAuth2
  # Auto expire content after a specified time
  def self.token_cache
    @token_cache ||= ActiveSupport::Cache::MemoryStore.new(expires_in: 30.minutes)
  end
end

module Rack::OAuth2::Bearer
  module RequestHelpers
    def heartbeat?
      path.match Conf::HEART_BEAT_REGEX
    end

    def has_token?
      bearer_token?
    end

    def bearer_token?
      !!bearer_token
    end

    def bearer_token
      regexp = Regexp.new(/Bearer\s+(.*)/i)

      if self.env.include?('HTTP_AUTHORIZATION')
        str = self.env['HTTP_AUTHORIZATION']
        matchdata = str.match(regexp)
        matchdata[1] if matchdata
      end
    end

    def valid_token?
      return false unless has_token?

      oauth_token_info_url = Conf::OAUTH_TOKEN_INFO_URL
      raise ArgumentError, 'Need oauth_token_info_url' unless oauth_token_info_url
      response = HTTP.get(oauth_token_info_url + bearer_token)
      valid = response.code == 200
      cache = Rack::OAuth2.token_cache
      cache.write(bearer_token, true) if valid
      store_insights(response) if valid
      valid
    end

    def cached_token?
      cache = Rack::OAuth2.token_cache
      cache.fetch(bearer_token)
    end

    def store_insights(response)
      # e.g. for a human user: 'leonardo', '/employees'
      # e.g. for a service...: 'stups_pacts', '/services'
      uid = JSON.parse(response.body)['uid']
      realm = JSON.parse(response.body)['realm'].delete('/')
      hsh = {iam_uid: uid, iam_realm: realm}
      ::NewRelic::Agent.add_custom_attributes(hsh)
      ::NewRelic::Agent.record_custom_event('users_kpi', hsh)
    end
  end
end
