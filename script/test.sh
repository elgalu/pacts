#!/usr/bin/env bash

# This script
# - builds pact_broker image from docker file
# - connects to the application to check it works
# - works in Linux, TravisCI and OSX

# set -e: exit asap if a command exits with a non-zero status
# set -x: print each command right before it is executed
set -xe

# Commented out as it eats stderr and `set -e` should suffice
#  trap 'echo "FAILED"; exit 1' ERR

echoerr() { awk " BEGIN { print \"$@\" > \"/dev/fd/2\" }" ; }

# print error and exit
die () {
  echoerr "ERROR: $0: $1"
  # if $2 is defined AND NOT EMPTY, use $2; otherwise, set to "150"
  errnum=${2-115}
  exit $errnum
}

# print error and exit
required_args () {
  # set -x: print each command right before it is executed
  set +x
  echo "" 1>&2
  echo "A postgres database on your host machine is required through below" 1>&2
  echo "environment variables. Read POSTGRESQL.md for instructions." 1>&2
  echo "" 1>&2
  echo "Set below environment variables with appropriate values for your database:" 1>&2
  echo "  export PACT_BROKER_DATABASE_USERNAME=postgres" 1>&2
  echo "  export PACT_BROKER_DATABASE_PASSWORD=postgres" 1>&2
  echo "  export PACT_BROKER_DATABASE_NAME=pact" 1>&2
  echo "  export PACT_BROKER_DATABASE_HOST=172.17.0.2" 1>&2
  echo "  export TOKENINFO_URL=\"https://info.service.example.com/oauth2/tokeninfo\"" 1>&2
  echo "  export TOKENINFO_PARAMS=\"?access_token=\"" 1>&2
  echo "  export APPDYNAMICS_ANALYTICS_API_ENDPOINT=\"https://demo.appdynamics.com\"" 1>&2
  echo "  export APPDYNAMICS_ACCOUNT_ID=\"customer1_zxcvcxv3232\"" 1>&2
  echo "  export APPDYNAMICS_API_KEY=\"j23423-sdasf-secret!!!\"" 1>&2
  echo "  export EMPLOYEES_API_URL=\"https://https://api.example.com/employees\"" 1>&2
  echo "  export SERVICES_API_URL=\"https://https://api.example.com/services\"" 1>&2
  echo "  export MYUSER=elgalu" 1>&2
  echo "" 1>&2
  echo "Current values:" 1>&2
  echo "  export PACT_BROKER_DATABASE_USERNAME='${PACT_BROKER_DATABASE_USERNAME}'" 1>&2
  echo "  export PACT_BROKER_DATABASE_PASSWORD='${PACT_BROKER_DATABASE_PASSWORD}'" 1>&2
  echo "  export PACT_BROKER_DATABASE_NAME='${PACT_BROKER_DATABASE_NAME}'" 1>&2
  echo "  export PACT_BROKER_DATABASE_HOST='${PACT_BROKER_DATABASE_HOST}'" 1>&2
  echo "  export TOKENINFO_URL='${TOKENINFO_URL}'" 1>&2
  echo "  export TOKENINFO_PARAMS='${TOKENINFO_PARAMS}'" 1>&2
  echo "  export APPDYNAMICS_ANALYTICS_API_ENDPOINT='${APPDYNAMICS_ANALYTICS_API_ENDPOINT}'" 1>&2
  echo "  export APPDYNAMICS_ACCOUNT_ID='${APPDYNAMICS_ACCOUNT_ID}'" 1>&2
  echo "  export APPDYNAMICS_API_KEY='${APPDYNAMICS_API_KEY}'" 1>&2
  echo "  export EMPLOYEES_API_URL='${EMPLOYEES_API_URL}'" 1>&2
  echo "  export SERVICES_API_URL='${SERVICES_API_URL}'" 1>&2
  echo "  export MYUSER='${MYUSER}'" 1>&2
  echo "" 1>&2
  echo "And ensure you have allowed external connections." 1>&2
  # if $2 is defined AND NOT EMPTY, use $2; otherwise, set to "150"
  errnum=${2-115}
  set -x
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
[ -z "${PACT_WAIT_TIMEOUT}" ]          && export PACT_WAIT_TIMEOUT="35s"
[ -z "${PACT_CONT_NAME}" ]             && export PACT_CONT_NAME="broker_app"
[ -z "${PSQL_CONT_NAME}" ]             && export PSQL_CONT_NAME="postgres_test"
[ -z "${SKIP_HTTPS_ENFORCER}" ]        && export SKIP_HTTPS_ENFORCER="true"
[ -z "${OAUTH2_ACCESS_TOKEN_URL}" ]    && export OAUTH2_ACCESS_TOKEN_URL="https://token.service.example.com/oauth2/access_token"
[ -z "${OAUTH2_ACCESS_TOKEN_PARAMS}" ] && export OAUTH2_ACCESS_TOKEN_PARAMS="?realm=/services"
[ -z "${OAUTH2_ACCESS_TOKEN_URL_PARAMS}" ] && \
  export OAUTH2_ACCESS_TOKEN_URL_PARAMS="${OAUTH2_ACCESS_TOKEN_URL}${OAUTH2_ACCESS_TOKEN_PARAMS}"
[ -z "${OAUTH2_SERVICES_ACCESS_TOKEN_URL_PARAMS}" ] && \
  export OAUTH2_SERVICES_ACCESS_TOKEN_URL_PARAMS="https://token.service.example.com/oauth2/access_token?realm=/services"
[ -z "${EMPLOYEES_API_URL}" ] && export EMPLOYEES_API_URL="https://api.example.com/employees"
[ -z "${SERVICES_API_URL}" ] && export SERVICES_API_URL="https://api.example.com/services"
[ -z "${APPDYNAMICS_ANALYTICS_API_ENDPOINT}" ] && export APPDYNAMICS_ANALYTICS_API_ENDPOINT="https://demo.appdynamics.com"
[ -z "${APPDYNAMICS_ACCOUNT_ID}" ]             && export APPDYNAMICS_ACCOUNT_ID="customer1_zxcvcxv3232"
[ -z "${APPDYNAMICS_API_KEY}" ]                && export APPDYNAMICS_API_KEY="j23423-sdasf-secret!!!"

if [ "$(uname)" == "Darwin" ]; then
  export GTIMEOUT="gtimeout"
else
  export GTIMEOUT="timeout"
fi

if ! zign --version; then die "This script $0 requires zign"; fi
if ! pg_isready --version; then
  die "This script $0 requires psql client, e.g. brew install postgresql"
fi
if ! ${GTIMEOUT} --version | grep coreutils; then
  die "This script $0 requires ${GTIMEOUT}, e.g. brew install coreutils"
fi

# ensure token works before continuing
zign token --user ${MYUSER} --url ${OAUTH2_ACCESS_TOKEN_URL_PARAMS} -n pact

# Cert issues
if [ ! -f "certs/zalando-service.crt" ]; then
  curl https://secure-static.ztat.net/ca/zalando-service.ca > certs/zalando-service.crt
fi
if [ ! -f "certs/zalando-root.crt" ]; then
  curl https://secure-static.ztat.net/ca/zalando-root.ca > certs/zalando-root.crt
fi

echo "Will build the pact broker"
docker build -t=pact_broker .

# Stop and remove any running broker_app container instances before updating
if docker ps -a | grep ${PACT_CONT_NAME}; then
  echo ""
  echo "Stopping and removing running instance of pact broker container"
  docker stop -t=1 ${PACT_CONT_NAME}
  docker rm -vf ${PACT_CONT_NAME}
  rm -f ../pact_broker/pact_broker.log
fi

# if [ "$(uname)" == "Darwin" ]; then
#   PORT_BIND="${PACT_BROKER_PORT}:${PACT_BROKER_PORT}"
#   if [ "true" == "$(command -v boot2docker > /dev/null 2>&1 && echo 'true' || echo 'false')" ]; then
#     test_ip=$(boot2docker ip)
#   else
#     if [ "true" == "$(command -v docker-machine > /dev/null 2>&1 && echo 'true' || echo 'false')" ]; then
#       test_ip=$(docker-machine ip default)
#     else
#       echo "Cannot detect either boot2docker or docker-machine" && exit 1
#     fi
#   fi
# else
PORT_BIND="${PACT_BROKER_PORT}"
# fi

if [ "${DISPOSABLE_PSQL}" == "true" ]; then
  # [ "$(uname)" == "Darwin" ] && die \
  #   "Running the disposable postgres is only supported in Linux for now."

  export PACT_BROKER_DATABASE_USERNAME=postgres
  export PACT_BROKER_DATABASE_NAME=pact
  PGUSER=${PACT_BROKER_DATABASE_USERNAME}
  PGDATABASE=${PACT_BROKER_DATABASE_NAME}
  if [ -z "${PACT_BROKER_DATABASE_PASSWORD}" ]; then
    export PACT_BROKER_DATABASE_PASSWORD="leo123"
    # if pwgen -n1 >/dev/null 2>&1; then
    #   export PACT_BROKER_DATABASE_PASSWORD=$(pwgen -c -n -1 $(echo $[ 7 + $[ RANDOM % 17 ]]) 1)
    # else
    #   export PACT_BROKER_DATABASE_PASSWORD="no_pwdgen_so_hardcoded_password"
    # fi
  fi
  export PGPASSWORD=$PACT_BROKER_DATABASE_PASSWORD

  # Run psql, e.g. postgres:9.4 / postgres:9.5.4
  PSQL_IMG=postgres:9.5.4
  docker pull ${PSQL_IMG}

  echo ""
  echo "Run the docker postgres image '${PSQL_IMG}'"
  # Using `--privileged` due to
  #  pg_ctl: could not send stop signal (PID: 55): Permission denied
  #  in TravisCI
  docker run -d --name=${PSQL_CONT_NAME} -p 5432:5432 \
    -e POSTGRES_PASSWORD=${PGPASSWORD} \
    -e PGPASSWORD \
    -e PGUSER \
    -e PGPORT="5432" \
    ${PSQL_IMG}
  sleep 4 && docker logs ${PSQL_CONT_NAME}

  ${GTIMEOUT} --foreground ${PSQL_WAIT_TIMEOUT} \
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
[ -z "${APPDYNAMICS_ANALYTICS_API_ENDPOINT}" ] && required_args
[ -z "${APPDYNAMICS_ACCOUNT_ID}" ] && required_args
[ -z "${APPDYNAMICS_API_KEY}" ] && required_args
[ -z "${EMPLOYEES_API_URL}" ] && required_args
[ -z "${SERVICES_API_URL}" ] && required_args
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
  -e APPDYNAMICS_ANALYTICS_API_ENDPOINT \
  -e APPDYNAMICS_ACCOUNT_ID \
  -e APPDYNAMICS_API_KEY \
  -e EMPLOYEES_API_URL \
  -e SERVICES_API_URL \
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
echo "Checking with valid user_token"
echo " at url: ${url}"
user_token=$(zign token --user ${MYUSER} --url ${OAUTH2_ACCESS_TOKEN_URL_PARAMS} -n pact)
# echo "Got user_token=$user_token"
curl -H "Accept:text/html" \
     -H "Authorization: Bearer $user_token" -s "${url}" 2>&1 \
   | grep "0 pacts" || report_pact_failed

echo ""
echo "Performance test with user_token verification"
echo " at url: ${url}/"
ab -n 100 -c 10 -k -H "Authorization: Bearer $user_token" "${url}/"

echo ""
echo "Checking with valid service_token"
echo " at url: ${url}"
# we will download credentials into the current working dir
export CREDENTIALS_DIR=.
export ACCOUNT="myteam-test"
export APPLICATION_ID="pacts-staging"
export MINT_S3_BUCKET="myorg-stups-mint-234567890123-us-east-3"
zaws login ${ACCOUNT} PowerUser
berry -a ${APPLICATION_ID} -m ${MINT_S3_BUCKET} --once .
# note `--url` is not supported so it can only be done through `export OAUTH2_ACCESS_TOKEN_URL=...`
export OAUTH2_ACCESS_TOKEN_URL="${OAUTH2_SERVICES_ACCESS_TOKEN_URL_PARAMS}"
# note `-n myapp-test` is essential magic here, else it doesn't work :/
service_token=$(zign token -n myapp-test)
echo "Got service_token=$service_token"
echo " it should look like a service token!"

url="https://pacts.myteam-test.example.org/ui/relationships"
curl -H "Accept:text/html" \
     -H "Authorization: Bearer $service_token" -s "${url}" 2>&1 \
   | grep -E "[0-9]+\spacts" || report_pact_failed

url="https://pacts.myteam.example.org/ui/relationships"
curl -H "Accept:text/html" \
     -H "Authorization: Bearer $service_token" -s "${url}" 2>&1 \
   | grep -E "[0-9]+\spacts" || report_pact_failed

# vers="v000"
vers="v001"

# Optionally also test on deployed version, on test
url="https://pacts-${vers}.myteam-test.example.org/ui/relationships"
curl -H "Accept:text/html" \
     -H "Authorization: Bearer $service_token" -s "${url}" 2>&1 \
   | grep -E "[0-9]+\spacts" || report_pact_failed

# Optionally also test on deployed version, on live
url="https://pacts-${vers}.myteam.example.org/ui/relationships"
curl -H "Accept:text/html" \
     -H "Authorization: Bearer $service_token" -s "${url}" 2>&1 \
   | grep -E "[0-9]+\spacts" || report_pact_failed

echo ""
echo "SUCCESS: All tests passed!"
