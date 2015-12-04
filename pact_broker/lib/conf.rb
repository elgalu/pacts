require './lib/validations'

module Conf
  # default token info endpoint to validate bearer tokens
  OAUTH_TOKEN_INFO_URL ||= ENV['OAUTH_TOKEN_INFO']

  # default response type
  JSON_CONT = {'Content-Type' => 'application/json'}

  # allow unsecure connections to heartbeat routes
  HEART_BEAT_REGEX = %r{^/diagnostic/status/heartbeat/?$}

  # Throttle security config
  # REQ_IP_LIMIT=3 REQ_IP_SECS=1 means access denied after 3 invalid requests per second
  REQ_IP_LIMIT = 3
  REQ_IP_SECS  = 1

  BLOCKED_REQUEST = {
    code: 429,
    message: 'AccessDenied',
    reason: 'blocked',
    error: 'request_blocked',
    error_description: 'RequestBlocked'
  }

  # OAuth2 errors can be one of
  #  ['invalid_request', 'invalid_token', 'insufficient_scope']
  #  ref: http://self-issued.info/docs/draft-ietf-oauth-v2-bearer.html
  INVALID_REQUEST = {
    code: 400,
    message: 'MissingTokenError',
    reason: 'unauthorized',
    error: 'invalid_request',
    error_description: 'MissingTokenError'
  }

  INVALID_TOKEN = {
    code: 401,
    message: 'InvalidTokenError',
    reason: 'unauthorized',
    error: 'invalid_token',
    error_description: 'InvalidTokenError'
  }

  INSUFFICIENT_SCOPE = {
    code: 401,
    message: 'InsufficientScopeError',
    reason: 'unauthorized',
    error: 'insufficient_scope',
    error_description: 'InsufficientScopeError'
  }
end
