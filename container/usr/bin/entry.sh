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

# Required params
[ -z "${OAUTH_TOKEN_INFO}" ] && die "Required env var OAUTH_TOKEN_INFO"
[ -z "${PACT_BROKER_PORT}" ] && die "Required env var PACT_BROKER_PORT"
[ -z "${BIND_TO}" ] && die "Required env var BIND_TO"
[ -z "${RACK_LOG}" ] && die "Required env var RACK_LOG"
[ -z "${RACK_THREADS_COUNT}" ] && die "Required env var RACK_THREADS_COUNT"

# Depending on the target server set our env vars
if [ "${STAGE}" == "live" ]; then
  export PACT_BROKER_DATABASE_HOST=${LIVE_PACT_BROKER_DATABASE_HOST}
  export PACT_BROKER_DATABASE_USERNAME=${LIVE_PACT_BROKER_DATABASE_USERNAME}
  export PACT_BROKER_DATABASE_NAME=${LIVE_PACT_BROKER_DATABASE_NAME}
  export PACT_BROKER_DATABASE_PASSWORD=${LIVE_PACT_BROKER_DATABASE_PASSWORD}
elif [ "${STAGE}" == "staging" ]; then
  export PACT_BROKER_DATABASE_HOST=${STAGING_PACT_BROKER_DATABASE_HOST}
  export PACT_BROKER_DATABASE_USERNAME=${STAGING_PACT_BROKER_DATABASE_USERNAME}
  export PACT_BROKER_DATABASE_NAME=${STAGING_PACT_BROKER_DATABASE_NAME}
  export PACT_BROKER_DATABASE_PASSWORD=${STAGING_PACT_BROKER_DATABASE_PASSWORD}
else
  die "STAGE can be either 'live' or 'staging'"
fi

# Rest of the required params
[ -z "${PACT_BROKER_DATABASE_USERNAME}" ] && die "Required env var PACT_BROKER_DATABASE_USERNAME"
[ -z "${PACT_BROKER_DATABASE_PASSWORD}" ] && die "Required env var PACT_BROKER_DATABASE_PASSWORD"
[ -z "${PACT_BROKER_DATABASE_HOST}" ] && die "Required env var PACT_BROKER_DATABASE_HOST"
[ -z "${PACT_BROKER_DATABASE_NAME}" ] && die "Required env var PACT_BROKER_DATABASE_NAME"

# Replace current process with the web server one
exec bundle exec thin --rackup config.ru \
                      --environment development \
                      --debug \
                      --address ${BIND_TO} \
                      --port ${PACT_BROKER_PORT} \
                      --threaded \
                      --threadpool-size ${RACK_THREADS_COUNT} \
                      start | tee ${RACK_LOG}
