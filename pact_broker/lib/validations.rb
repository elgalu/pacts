# Validation: required environment variables
%w(PACT_BROKER_DATABASE_USERNAME
   PACT_BROKER_DATABASE_PASSWORD
   PACT_BROKER_DATABASE_HOST
   PACT_BROKER_DATABASE_NAME
   TOKENINFO_URL_PARAMS).each do |var|
  raise ArgumentError, "Need environment variable '#{var}'" unless ENV[var]
end
