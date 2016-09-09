#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# echo fn that outputs to stderr http://stackoverflow.com/a/2990533/511069
echoerr() {
  cat <<< "$@" 1>&2;
}

# print error and exit
die () {
  echoerr "ERROR: $1"
  # if $2 is defined AND NOT EMPTY, use $2; otherwise, set to "160"
  errnum=${2-160}
  exit $errnum
}

# Required params or defaults
[ -z "${TOKENINFO_URL}" ] && die "Required env var TOKENINFO_URL"
[ -z "${PACT_BROKER_PORT}" ] && die "Required env var PACT_BROKER_PORT"
[ -z "${BIND_TO}" ] && die "Required env var BIND_TO"
[ -z "${RACK_LOG}" ] && die "Required env var RACK_LOG"
[ -z "${RACK_THREADS_COUNT}" ] && die "Required env var RACK_THREADS_COUNT"

# Defaults
[ -z "${SKIP_HTTPS_ENFORCER}" ] && export SKIP_HTTPS_ENFORCER=false
[ -z "${TOKENINFO_PARAMS}" ] && export TOKENINFO_PARAMS="?access_token=" 
[ -z "${EMPLOYEES_API_URL}" ] && export EMPLOYEES_API_URL="https://api.example.com/employees"
[ -z "${OAUTH2_ACCESS_TOKEN_URL}" ] && export OAUTH2_ACCESS_TOKEN_URL="https://token.service.example.com/oauth2/access_token"
[ -z "${OAUTH2_ACCESS_TOKEN_PARAMS}" ] && export OAUTH2_ACCESS_TOKEN_PARAMS="?realm=/services"
[ -z "${APPDYNAMICS_TEAM_API_ACCN}" ] && export APPDYNAMICS_TEAM_API_ACCN="ourAPIaccount"
[ -z "${APPDYNAMICS_TEAM_API_USER}" ] && export APPDYNAMICS_TEAM_API_USER="ourAPIuser"
[ -z "${APPDYNAMICS_TEAM_API_PASS}" ] && export APPDYNAMICS_TEAM_API_PASS="someSecret!"
[ -z "${APPDYNAMICS_API_ENDPOINT}" ] && export APPDYNAMICS_API_ENDPOINT="http://demo.appdynamics.com"
[ -z "${APPDYNAMICS_ANALYTICS_API_ENDPOINT}" ] && export APPDYNAMICS_ANALYTICS_API_ENDPOINT="https://demo.appdynamics.com"
[ -z "${APPDYNAMICS_ACCOUNT_ID}" ] && export APPDYNAMICS_ACCOUNT_ID="customer1_zxcvcxv3232"
[ -z "${APPDYNAMICS_API_KEY}" ] && export APPDYNAMICS_API_KEY="j23423-sdasf-secret!!!"
# Database
[ -z "${LIVE_PACT_BROKER_DATABASE_NAME}" ] && export LIVE_PACT_BROKER_DATABASE_NAME="live_pacts"
[ -z "${LIVE_PACT_BROKER_DATABASE_HOST}" ] && export LIVE_PACT_BROKER_DATABASE_HOST="aws:kms:SECRET!!!"
[ -z "${LIVE_PACT_BROKER_DATABASE_USERNAME}" ] && export LIVE_PACT_BROKER_DATABASE_USERNAME="aws:kms:SECRET!!!"
[ -z "${LIVE_PACT_BROKER_DATABASE_PASSWORD}" ] && export LIVE_PACT_BROKER_DATABASE_PASSWORD="aws:kms:SECRET!!!"
[ -z "${STAGING_PACT_BROKER_DATABASE_NAME}" ] && export STAGING_PACT_BROKER_DATABASE_NAME="staging_pact"
[ -z "${STAGING_PACT_BROKER_DATABASE_HOST}" ] && export STAGING_PACT_BROKER_DATABASE_HOST="aws:kms:SECRET!!!"
[ -z "${STAGING_PACT_BROKER_DATABASE_USERNAME}" ] && export STAGING_PACT_BROKER_DATABASE_USERNAME="aws:kms:SECRET!!!"
[ -z "${STAGING_PACT_BROKER_DATABASE_PASSWORD}" ] && export STAGING_PACT_BROKER_DATABASE_PASSWORD="aws:kms:SECRET!!!"

# Generate token full url if not already present
[ -z "${TOKENINFO_URL_PARAMS}" ] && \
  export TOKENINFO_URL_PARAMS="${TOKENINFO_URL}${TOKENINFO_PARAMS}"
[ -z "${OAUTH2_ACCESS_TOKEN_URL_PARAMS}" ] && \
  export OAUTH2_ACCESS_TOKEN_URL_PARAMS="${OAUTH2_ACCESS_TOKEN_URL}${OAUTH2_ACCESS_TOKEN_PARAMS}"

# Depending on the target server set our env vars
if [ "${STAGE}" == "live" ]; then
  export PACT_BROKER_DATABASE_HOST=${LIVE_PACT_BROKER_DATABASE_HOST}
  export PACT_BROKER_DATABASE_USERNAME=${LIVE_PACT_BROKER_DATABASE_USERNAME}
  export PACT_BROKER_DATABASE_NAME=${LIVE_PACT_BROKER_DATABASE_NAME}
  export PACT_BROKER_DATABASE_PASSWORD=${LIVE_PACT_BROKER_DATABASE_PASSWORD}
elif [ "${STAGE}" == "test" ]; then
  export PACT_BROKER_DATABASE_HOST=${STAGING_PACT_BROKER_DATABASE_HOST}
  export PACT_BROKER_DATABASE_USERNAME=${STAGING_PACT_BROKER_DATABASE_USERNAME}
  export PACT_BROKER_DATABASE_NAME=${STAGING_PACT_BROKER_DATABASE_NAME}
  export PACT_BROKER_DATABASE_PASSWORD=${STAGING_PACT_BROKER_DATABASE_PASSWORD}
elif [ "${STAGE}" == "local" ]; then
  echo "Testing"
else
  die "STAGE must be one of: live, test, local"
fi

# Rest of the required params
[ -z "${PACT_BROKER_DATABASE_USERNAME}" ] && die "Required env var PACT_BROKER_DATABASE_USERNAME"
[ -z "${PACT_BROKER_DATABASE_PASSWORD}" ] && die "Required env var PACT_BROKER_DATABASE_PASSWORD"
[ -z "${PACT_BROKER_DATABASE_HOST}" ] && die "Required env var PACT_BROKER_DATABASE_HOST"
[ -z "${PACT_BROKER_DATABASE_NAME}" ] && die "Required env var PACT_BROKER_DATABASE_NAME"

# Taupage compatible helper for adding AppDynamics to your JVM process
#  export JAVA_OPTS="${JAVA_OPTS} $(appdynamics-agent)"

# Torquebox + JBoss web server
[ -z "${JBOSS_HOME}" ] && die "Required env var JBOSS_HOME"
sed -i -- "s/8080/${PACT_BROKER_PORT}/g" ${JBOSS_HOME}/standalone/configuration/standalone.xml
sed -i -- "s/8080/${PACT_BROKER_PORT}/g" ${JBOSS_HOME}/standalone/configuration/standalone-ha.xml
sed -i -- "s/8080/${PACT_BROKER_PORT}/g" ${JBOSS_HOME}/domain/configuration/domain.xml
exec jruby -S torquebox run \
  --max-threads=${RACK_THREADS_COUNT} \
  --bind-address="${BIND_TO}" \
  --jvm-options="$(appdynamics-agent)"

# Alternatives
# puma (MRI / JRuby)
# exec bundle exec puma --environment development \
#                       --debug \
#                       --bind "tcp://${BIND_TO}:${PACT_BROKER_PORT}" \
#                       --threads "0:${RACK_THREADS_COUNT}" \
#                       config.ru | tee ${RACK_LOG}

# thin (MRI)
# exec bundle exec thin --rackup config.ru \
#                       --environment development \
#                       --debug \
#                       --address ${BIND_TO} \
#                       --port ${PACT_BROKER_PORT} \
#                       --threaded \
#                       --threadpool-size ${RACK_THREADS_COUNT} \
#                       start | tee ${RACK_LOG}
