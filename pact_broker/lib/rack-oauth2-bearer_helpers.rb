require 'http'
require 'active_support/cache'
# require 'new_relic/agent'
require 'csv'

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

      oauth_token_info_url = Conf::TOKENINFO_URL_PARAMS
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
      hsh = get_insights(response)
      write_to_csv(hsh)
    end

    def get_insights(response)
      # e.g. for a human user: 'leo', '/employees'
      # e.g. for a service...: 'stups_pacts', '/services'
      uid = JSON.parse(response.body)['uid']
      realm = JSON.parse(response.body)['realm'].delete('/')
      team = get_team(uid)
      hsh = {iam_uid: uid, iam_realm: realm, team: team}
    end

    def get_team(uid)
      'todo'
    end

    def write_to_csv(hsh)
      # e.g.
      #  hsh = {iam_uid: 'leo', iam_realm: '/employees', team: 'tip'}
      #  ary #=> ["iam_uid: leo", "iam_realm: /employees", "team: tip"]
      ary = hsh.map { |k,v| "#{k}: #{v}" }
      # File.open("pacts_usage.txt", "a+") { |line| line << ary }
      CSV.open("pacts_usage.csv", "a+") { |csv| csv << ary }
      # e.g.
      #  iam_uid: leo,iam_realm: /employees,team: tip
    end

    def post_to_appdynamics(hsh)
      # e.g.
      #  hsh = {iam_uid: 'leo', iam_realm: '/employees', team: 'tip'}
      #  keys   #=> ["iam_uid", "iam_realm", "team"]
      #  values #=> ["leo", "employees", "tip"]
      keys = hsh.keys.map(&:to_s)
      values = hsh.values.map(&:to_s).map { |v| v.gsub('/','') }
      # e.g.
      #  "propertynames=iam_uid&propertynames=iam_realm&propertynames=team"
      propertynames = keys.map { |v| "propertynames=#{v}" }.join('&')
      # e.g.
      #  "propertyvalues=leo&propertyvalues=employees&propertyvalues=tip"
      propertyvalues = values.map { |v| "propertyvalues=#{v}" }.join('&')
      # continue building the url query by reading appdynamics_rest_api.md
    end

    def post_to_newrelic(hsh)
      # ::NewRelic::Agent.add_custom_attributes(hsh)
      # ::NewRelic::Agent.record_custom_event('users_kpi', hsh)
    end
  end
end
