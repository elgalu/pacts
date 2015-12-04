require 'rack/attack'
require 'active_support/cache'

require './lib/validations'
require './lib/conf'
require './lib/rack-oauth2-bearer'
require './lib/rack-oauth2-bearer_helpers'

## Extend them with our request helpers
class Rack::Attack::Request
  include Rack::OAuth2::Bearer::RequestHelpers
end

class Rack::Attack
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  # e.g. throttle spammy clients due to too many (60rqpm) requests
  # throttle('req/ip', limit: 300, period: 5.minutes) do |request|
  #   request.ip
  # end

  # Prevent brute-force token check attacks
  # TODO: log banned IPs
  throttle('req/ip', limit: Conf::REQ_IP_LIMIT, period: (Conf::REQ_IP_SECS).seconds) do |request|
    request.ip unless request.heartbeat? || request.valid_token?
  end

  # Returns HTTP 429 for throttled responses
  self.throttled_response = lambda do |env|
    [ Conf::BLOCKED_REQUEST[:code], Conf::JSON_CONT, [Conf::BLOCKED_REQUEST.to_json] ]
  end
end
