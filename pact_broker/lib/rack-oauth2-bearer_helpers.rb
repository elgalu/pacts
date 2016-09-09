require 'http'
require 'socket'
require 'date'
require 'active_support/cache'
require 'csv'
require 'ostruct'
require 'json'
require 'httparty'

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

    def get_env_type
      ENV.include?('STAGE') ? ENV['STAGE'] : 'local'
    end

    def get_app_id
      app_id = ''
      app_id = 'pacts' if get_env_type == 'live'
      app_id = 'pacts-staging' if get_env_type == 'staging'
      app_id
    end

    def get_remote_ip
      # e.g. "REMOTE_ADDR"=>"172.17.0.1"
      self.env['REMOTE_ADDR'] if self.env.include?('REMOTE_ADDR')
      # ip=Socket.ip_address_list.detect{ |intf| intf.ipv4_private? }
      # ip_address = ip ? ip.ip_address : "unknown"
    end

    def get_target_host
      # e.g. "HTTP_HOST"=>"172.17.0.3:443"
      self.env['HTTP_HOST'] if self.env.include?('HTTP_HOST')
    end

    def get_url1
      # e.g.
      #      "rack.url_scheme"=>"http"
      #      "SERVER_NAME"=>"172.17.0.3"
      #      "SERVER_PORT"=>"443"
      #      "REQUEST_URI"=>"/ui/relationships"
      #      "QUERY_STRING"=>""
      url1 = ""
      url1 += self.env['rack.url_scheme'] if self.env.include?('rack.url_scheme')
      url1 += '://'
      url1 += self.env['SERVER_NAME'] if self.env.include?('SERVER_NAME')
      url1 += ':' if self.env.include?('SERVER_PORT')
      url1 += self.env['SERVER_PORT'] if self.env.include?('SERVER_PORT')
      url1 += self.env['REQUEST_URI'] if self.env.include?('REQUEST_URI')
      url1 += '?' if self.env.include?('QUERY_STRING') && self.env['QUERY_STRING'] != ''
      url1 += self.env['QUERY_STRING'] if self.env.include?('QUERY_STRING') && self.env['QUERY_STRING'] != ''
      url1
    end

    def get_url2
      # e.g. "REQUEST_METHOD"=>"GET"
      self.env['REQUEST_METHOD'] if self.env.include?('REQUEST_METHOD')
    end

    def get_description
      # e.g. "HTTP_USER_AGENT"=>"curl/7.47.0"
      self.env['HTTP_USER_AGENT'] if self.env.include?('HTTP_USER_AGENT')
    end

    def valid_token?
      return false unless has_token?
      return true if cached_token?

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
      PactBroker.logger.info("get_insights: #{hsh.to_s}")
      # write_to_csv(hsh)
      post_to_appdynamics(hsh)
    end

    def get_insights(response)
      # e.g. for a human user: 'leo', '/employees'
      # e.g. for a service...: 'stups_pacts', '/services'
      uid = JSON.parse(response.body)['uid']
      realm = JSON.parse(response.body)['realm'].delete('/')

      payload_hsh = {
        service: 'pacts',
        env_type: get_env_type,
        app_id: get_app_id,
        uid: uid,
        env_user: ENV['USER'],
        realm: realm,
        team: get_team(uid),
        ip_address: get_remote_ip,
        target_host: get_target_host,
        description: get_description,
        url1: get_url1,
        url2: get_url2
      }

      payload_hsh
    end

    def get_token()
      # we already have the user token, let's use it to get the team
      bearer_token
      # %x(zign token -n imposter uid).delete("\n")
    end

    def get_team(uid)
      raise ArgumentError, 'Need uid' unless uid

      employees_api_url = Conf::EMPLOYEES_API_URL
      raise ArgumentError, 'Need employees_api_url' unless employees_api_url

      token = get_token()
      PactBroker.logger.info("Got a token, shuffled: #{token.chars.to_a.shuffle.join}")
      raise ArgumentError, 'Need token' unless token

      url = "#{employees_api_url}/#{uid}"
      # require 'rest-client' #not working with Torquebox
      # response = RestClient.get(url, Authorization: "Bearer #{token}")
      response = HTTParty.get url, :headers => {"Authorization" => "Bearer #{token}"}
      raise response.to_s if response.code != 200
      hsh = JSON.parse(response.body)
      teams = hsh['teams'].
                select { |t| t['type'] == 'official' }.
                map    { |t| t['nickname'] }
      teams.join(',')
    end

    def write_to_csv(hsh)
      # e.g.
      #  hsh = {uid: 'leo', realm: 'employees', team: 'tip'}
      #  ary #=> ["uid: leo", "realm: employees", "team: tip"]
      ary = hsh.map { |k,v| "#{k}: #{v}" }
      # File.open("pacts_usage.txt", "a+") { |line| line << ary }
      CSV.open("pacts_usage.csv", "a+") { |csv| csv << ary }
      # e.g.
      #  uid: leo,realm: employees,team: tip
    end

    def post_to_appdynamics(payload_hsh)
      # e.g.
      #  payload_hsh = {uid: 'leo', realm: 'employees', team: 'tip'}
      raise ArgumentError, 'Need payload_hsh' unless payload_hsh
      raise ArgumentError, 'Need payload_hsh to be a Hash' unless payload_hsh.is_a? Hash

      appd_analytics_api_endpoint = Conf::APPDYNAMICS_ANALYTICS_API_ENDPOINT
      appd_account_id = Conf::APPDYNAMICS_ACCOUNT_ID
      appd_api_key = Conf::APPDYNAMICS_API_KEY

      raise ArgumentError, 'Need appd_analytics_api_endpoint' unless appd_analytics_api_endpoint
      raise ArgumentError, 'Need appd_account_id' unless appd_account_id
      raise ArgumentError, 'Need appd_api_key' unless appd_api_key

      url = "#{appd_analytics_api_endpoint}/events/publish/tip_kpis"
      headers = {
        'X-Events-API-AccountName' => appd_account_id,
        'X-Events-API-Key' => appd_api_key,
        'Content-type' => 'application/vnd.appd.events+json;v=1'
      }
      body = [payload_hsh].to_json

      PactBroker.logger.info("post_to_appdynamics:url:#{url}")
      # PactBroker.logger.info("post_to_appdynamics:headers: #{headers.to_s}")
      PactBroker.logger.info("post_to_appdynamics:body:#{body.to_s}")
      # require 'rest-client' #not working with Torquebox
      # response = RestClient.post(url, [payload_hsh].to_json, headers)
      response = HTTParty.post url, headers: headers, body: body
      raise response.to_s if response.code != 200

      PactBroker.logger.info("post_to_appdynamics: response.body: #{response.body}")
      raise "Failed to POST KPIs to AppDynamics #{response.body}" unless response.code == 200
      response
    end

    def old_post_to_appdynamics(hsh)
      # e.g.
      #  hsh = {uid: 'leo', realm: 'employees', team: 'tip'}
      #  keys   #=> ["uid", "realm", "team"]
      #  values #=> ["leo", "employees", "tip"]
      keys = hsh.keys.map(&:to_s)
      values = hsh.values.map(&:to_s).map { |v| v.gsub('/','') }
      # e.g.
      #  "propertynames=uid&propertynames=realm&propertynames=team"
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
