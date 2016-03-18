#!/usr/bin/env bash

# This script
# - builds pact_broker image from docker file
# - connects to the application to check it works
# - works in Linux, TravisCI and OSX

# Exit immediately if a command exits with a non-zero status
set -e

# Commented out as it eats stderr and `set -e` should suffice
#  trap 'echo "FAILED"; exit 1' ERR

# echo fn that outputs to stderr http://stackoverflow.com/a/2990533/511069
echoerr() {
  cat <<< "$@" 1>&2;
}

# print error and exit
die () {
  echoerr "ERROR: $0: $1"
  # if $2 is defined AND NOT EMPTY, use $2; otherwise, set to "150"
  errnum=${2-115}
  exit $errnum
}

# print error and exit
required_args () {
  echoerr ""
  echoerr "A postgres database on your host machine is required through below"
  echoerr "environment variables. Read POSTGRESQL.md for instructions."
  echoerr ""
  echoerr "Set below environment variables with appropriate values for your database:"
  echoerr "  export PACT_BROKER_DATABASE_USERNAME=postgres"
  echoerr "  export PACT_BROKER_DATABASE_PASSWORD=postgres"
  echoerr "  export PACT_BROKER_DATABASE_NAME=pact"
  echoerr "  export PACT_BROKER_DATABASE_HOST=172.17.0.2"
  echoerr "  export TOKENINFO_URL=\"https://info.service.example.com/oauth2/tokeninfo\""
  echoerr "  export TOKENINFO_PARAMS=\"?access_token=\""
  echoerr "  export MYUSER=elgalu"
  echoerr ""
  echoerr "Current values:"
  echoerr "  export PACT_BROKER_DATABASE_USERNAME='${PACT_BROKER_DATABASE_USERNAME}'"
  echoerr "  export PACT_BROKER_DATABASE_PASSWORD='${PACT_BROKER_DATABASE_PASSWORD}'"
  echoerr "  export PACT_BROKER_DATABASE_NAME='${PACT_BROKER_DATABASE_NAME}'"
  echoerr "  export PACT_BROKER_DATABASE_HOST='${PACT_BROKER_DATABASE_HOST}'"
  echoerr "  export TOKENINFO_URL='${TOKENINFO_URL}'"
  echoerr "  export TOKENINFO_PARAMS='${TOKENINFO_PARAMS}'"
  echoerr "  export MYUSER='${MYUSER}'"
  echoerr ""
  echoerr "And ensure you have allowed external connections."
  # if $2 is defined AND NOT EMPTY, use $2; otherwise, set to "150"
  errnum=${2-115}
  exit $errnum
}

# show docker logs if any then die
report_postgres_failed () {
  docker logs ${PSQL_CONT_NAME} || true
  die "Postgres failed to start"
}

# show docker logs if any then die
report_pact_failed () {
  docker logs ${PACT_CONT_NAME} || true
  die "Pact Broker failed"
}

if [ "${TRAVIS}" == "true" ]; then
  DISPOSABLE_PSQL=true
fi

# defaults
[ -z "${PACT_BROKER_PORT}" ]           && export PACT_BROKER_PORT=443
[ -z "${BIND_TO}" ]                    && export BIND_TO="0.0.0.0"
[ -z "${PSQL_WAIT_TIMEOUT}" ]          && export PSQL_WAIT_TIMEOUT="10s"
[ -z "${PACT_WAIT_TIMEOUT}" ]          && export PACT_WAIT_TIMEOUT="15s"
[ -z "${PACT_CONT_NAME}" ]             && export PACT_CONT_NAME="broker_app"
[ -z "${PSQL_CONT_NAME}" ]             && export PSQL_CONT_NAME="postgres_test"
[ -z "${SKIP_HTTPS_ENFORCER}" ]        && export SKIP_HTTPS_ENFORCER="true"
[ -z "${OAUTH2_ACCESS_TOKEN_URL}" ]    && export OAUTH2_ACCESS_TOKEN_URL="https://token.example.com/access_token"
[ -z "${OAUTH2_ACCESS_TOKEN_PARAMS}" ] && export OAUTH2_ACCESS_TOKEN_PARAMS="?realm=/employees"
[ -z "${OAUTH2_ACCESS_TOKEN_URL_PARAMS}" ] && \
  export OAUTH2_ACCESS_TOKEN_URL_PARAMS="${OAUTH2_ACCESS_TOKEN_URL}${OAUTH2_ACCESS_TOKEN_PARAMS}"

# ensure token works before continuing
zign token --user ${MYUSER} --url ${OAUTH2_ACCESS_TOKEN_URL_PARAMS} -n pact

# Cert issues
curl https://secure-static.ztat.net/ca/zalando-service.ca > certs/zalando-service.crt
curl https://secure-static.ztat.net/ca/zalando-root.ca > certs/zalando-root.crt

echo "Will build the pact broker"
docker build -t=pact_broker .

# Stop and remove any running broker_app container instances before updating
if docker ps -a | grep ${PACT_CONT_NAME}; then
  echo ""
  echo "Stopping and removing running instance of pact broker container"
  docker stop -t=1 ${PACT_CONT_NAME}
  docker rm ${PACT_CONT_NAME}
fi

if [ "$(uname)" == "Darwin" ]; then
  PORT_BIND="${PACT_BROKER_PORT}:${PACT_BROKER_PORT}"
  if [ "true" == "$(command -v boot2docker > /dev/null 2>&1 && echo 'true' || echo 'false')" ]; then
    test_ip=$(boot2docker ip)
  else
    if [ "true" == "$(command -v docker-machine > /dev/null 2>&1 && echo 'true' || echo 'false')" ]; then
      test_ip=$(docker-machine ip default)
    else
      echo "Cannot detect either boot2docker or docker-machine" && exit 1
    fi
  fi
else
  PORT_BIND="${PACT_BROKER_PORT}"
fi

if [ "${DISPOSABLE_PSQL}" == "true" ]; then
  [ "$(uname)" == "Darwin" ] && die \
    "Running the disposable postgres is only supported in Linux for now."

  export PACT_BROKER_DATABASE_USERNAME=postgres
  export PACT_BROKER_DATABASE_NAME=pact
  PGUSER=${PACT_BROKER_DATABASE_USERNAME}
  PGDATABASE=${PACT_BROKER_DATABASE_NAME}
  if [ -z "${PACT_BROKER_DATABASE_PASSWORD}" ]; then
    if pwgen -n1 >/dev/null 2>&1; then
      export PACT_BROKER_DATABASE_PASSWORD=$(pwgen -c -n -1 $(echo $[ 7 + $[ RANDOM % 17 ]]) 1)
    else
      export PACT_BROKER_DATABASE_PASSWORD="no_pwdgen_so_hardcoded_password"
    fi
  fi
  export PGPASSWORD=$PACT_BROKER_DATABASE_PASSWORD

  # Run psql, e.g. postgres:9.4.5 / postgres:9.4.6 / postgres:9.4
  PSQL_IMG=postgres:9.4.6
  docker pull ${PSQL_IMG}

  echo ""
  echo "Run the docker postgres image '${PSQL_IMG}'"
  # Using `--privileged` due to
  #  pg_ctl: could not send stop signal (PID: 55): Permission denied
  #  in TravisCI
  docker run -d --name=${PSQL_CONT_NAME} -p 5432 \
    -e POSTGRES_PASSWORD=${PGPASSWORD} \
    -e PGPASSWORD \
    -e PGUSER \
    -e PGPORT="5432" \
    ${PSQL_IMG}
  sleep 1 && docker logs ${PSQL_CONT_NAME}

  timeout --foreground ${PSQL_WAIT_TIMEOUT} \
    $(dirname "$0")/wait_psql.sh ${PSQL_CONT_NAME} || report_postgres_failed

  export PACT_BROKER_DATABASE_HOST=`docker inspect -f '{{ .NetworkSettings.IPAddress }}' ${PSQL_CONT_NAME}`
  echo "Postgres container IP is: ${PACT_BROKER_DATABASE_HOST}"

  echo ""
  echo "Create the pact database '${PGDATABASE}'"
  docker exec -ti ${PSQL_CONT_NAME} sh -c \
    "PGPASSWORD=${PGPASSWORD} psql -U ${PGUSER} -c 'CREATE DATABASE ${PGDATABASE};'"
  docker exec -ti ${PSQL_CONT_NAME} sh -c \
    "PGPASSWORD=${PGPASSWORD} psql -U ${PGUSER} -c '\connect ${PGDATABASE}'"
fi

# Validate required variables
[ -z "${PACT_BROKER_DATABASE_USERNAME}" ] && required_args
[ -z "${PACT_BROKER_DATABASE_PASSWORD}" ] && required_args
[ -z "${PACT_BROKER_DATABASE_HOST}" ] && required_args
[ -z "${PACT_BROKER_DATABASE_NAME}" ] && required_args
[ -z "${TOKENINFO_URL}" ] && required_args
[ -z "${TOKENINFO_PARAMS}" ] && required_args
[ -z "${MYUSER}" ] && required_args

export TOKENINFO_URL_PARAMS="${TOKENINFO_URL}${TOKENINFO_PARAMS}"
echo "TOKENINFO_URL_PARAMS=${TOKENINFO_URL_PARAMS}"

echo ""
echo "Run the built Pact Broker"
# Using `--privileged` due to unspecified issues in TravisCI
docker run --name=${PACT_CONT_NAME} -d -p ${PORT_BIND} \
  -e PACT_BROKER_DATABASE_USERNAME \
  -e PACT_BROKER_DATABASE_PASSWORD \
  -e PACT_BROKER_PORT \
  -e BIND_TO \
  -e PACT_BROKER_DATABASE_HOST \
  -e PACT_BROKER_DATABASE_NAME \
  -e SKIP_HTTPS_ENFORCER \
  -e TOKENINFO_URL \
  -e TOKENINFO_PARAMS \
  -e TOKENINFO_URL_PARAMS \
  -e STAGE=local \
  pact_broker
sleep 2 && docker logs ${PACT_CONT_NAME}

echo ""
echo "Checking that the Pact Broker container is still up and running"
docker inspect -f "{{ .State.Running }}" ${PACT_CONT_NAME} | grep true || die \
  "The Pact Broker container is not running!"

echo ""
echo "Checking that server can be connected from within the Docker container"
docker exec ${PACT_CONT_NAME} wait_ready ${PACT_WAIT_TIMEOUT} || report_pact_failed

if [ -z "${test_ip}" ]; then
  test_ip=`docker inspect -f='{{ .NetworkSettings.IPAddress }}' ${PACT_CONT_NAME}`
fi

echo ""
echo "Checking that server can be connected from outside the Docker container"
export PACT_BROKER_HOST=${test_ip}
$(dirname "$0")/../container/usr/bin/wait_ready ${PACT_WAIT_TIMEOUT}

url="http://${test_ip}:${PACT_BROKER_PORT}/ui/relationships"

# echo ""
# echo "Checking that server accepts and return HTML from outside"
# echo " at url: ${url}"
# curl -H "Accept:text/html" -s "${url}" || curl -H "Accept:text/html" "${url}" || report_pact_failed

echo ""
echo "Checking that server returns 400 MissingTokenError from outside"
echo " at url: ${url}"
curl -H "Content-Type: application/json" -s "${url}" 2>&1 \
   | grep "MissingTokenError" \
  || curl -H "Accept:text/html" "${url}" || report_pact_failed

echo ""
echo "Checking that server returns 401 InvalidTokenError from outside"
echo " at url: ${url}"
curl -H "Content-Type: application/json" -s "${url}" 2>&1 \
   | grep "InvalidTokenError" \
  || curl -H "Accept:text/html" "${url}" \
          -H "Authorization: Bearer INVALIDtoken" || report_pact_failed
echo ""

# echo ""
# echo "Checking for specific HTML content from outside: '0 pacts'"
# echo " at url: ${url}"
# curl -H "Accept:text/html" -s "${url}" | grep "0 pacts" || report_pact_failed

# echo ""
# echo "Checking that server accepts and responds with status 200"
# response_code=$(curl -s -o /dev/null -w "%{http_code}" http://${test_ip}:${PACT_BROKER_PORT})

# if [[ "${response_code}" != '200' ]]; then
#   die "While checking HTML response status 200"
# fi

echo ""
echo "Checking with valid token"
echo " at url: ${url}"
token=$(zign token --user ${MYUSER} --url ${OAUTH2_ACCESS_TOKEN_URL_PARAMS} -n pact)
# echo "Got token=$token"
curl -H "Accept:text/html" \
     -H "Authorization: Bearer $token" -s "${url}" 2>&1 \
   | grep "0 pacts" || report_pact_failed

echo ""
echo "Performance test with token verification"
echo " at url: ${url}/"
ab -n 100 -c 10 -k -H "Authorization: Bearer $token" "${url}/"

echo ""
echo "SUCCESS: All tests passed!"
