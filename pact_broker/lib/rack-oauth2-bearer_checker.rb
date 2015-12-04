require 'json'
require 'rack'

require './lib/validations'
require './lib/conf'
require './lib/rack-oauth2-bearer'
require './lib/rack-oauth2-bearer_helpers'

class Rack::OAuth2::Bearer::Request < ::Rack::Request
  include Rack::OAuth2::Bearer::RequestHelpers
end

class Rack::OAuth2::Bearer::Checker
  attr_accessor :request, :scopes

  def initialize(app, scopes = [])
    @app = app
    @scopes = scopes
  end

  def call(env)
    # create a new oauth2 bearer decorated request object
    request = Rack::OAuth2::Bearer::Request.new(env)

    # let pass hearbeat requests
    return @app.call(env) if request.heartbeat?

    return [ Conf::INVALID_REQUEST[:code],
             Conf::JSON_CONT,
             [Conf::INVALID_REQUEST.to_json] ] unless request.has_token?

    return @app.call(env) if request.cached_token?

    return [ Conf::INVALID_TOKEN[:code],
             Conf::JSON_CONT,
             [Conf::INVALID_TOKEN.to_json] ] unless request.valid_token?

    # TODO: check missing scope or validate by uid or realm employees or user team or whatever logic
    #  return [ 401, Conf::JSON_CONT, [Conf::MISSING_SCOPE.to_json] ] unless self.request.has_scope?

    # Call the upper layers, i.e. the pact broker
    @app.call(env)
  end
end
