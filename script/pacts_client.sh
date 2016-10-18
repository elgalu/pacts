#!/bin/bash

# The script is supposed to run on local environment as well as on AWS Jenkinses.
# Usage: pacts_upload.sh MODE [OPTIONS]
# Available modes/options:
# get --provider=PROVIDER --consumer=CONSUMER [--version=VERSION] |
# put [--dir=./target/pacts] [--depth=1] [--version=VERSION] |
# del --provider=PROVIDER --consumer=CONSUMER [--version=VERSION] |
# del_user [--user=PROVIDER | CONSUMER]
# test
#
# To run from Jenkins, uncomment and paste everything below this line to the build step that follows unit tests:
# cat >pacts_upload.sh <<'__EOF__'
set -e

DIR_DEFAULT=./target/pacts
DATETIME=`date "+%Y%m%d.%H%M%S.%3N"`
DEPTH_MIN=0
DEPTH_MAX=3

MODES="get|put|del|del_user|test"
READ_CHECK=1
JENKINS_RUN=/tools/run
ZIGN_URL="https://token.example.com/access_token"
PACT_BROKER_URL="https://pacts.myteam-test.example.org"

err() {
  >&2 echo -e "${1}"
  exit 1
}

token_get() {
  echo "Getting token..."
  if [ -x "${JENKINS_RUN}" ]; then
    PACT_TOKEN=`${JENKINS_RUN} :stups -- zign token -n pacts`
  else
    PACT_TOKEN=`zign token --url "${ZIGN_URL}" -n pacts`
  fi
}

pact_get() {
  if [[ "${PACT_VERSION}" == "latest" ]]; then
    RES_PACT=`curl -s -H "Authorization: Bearer ${PACT_TOKEN}" "${PACT_BROKER_URL}/pacts/provider/${PACT_PROVIDER}/consumer/${PACT_CONSUMER}/${PACT_VERSION}"`
  else
    RES_PACT=`curl -s -H "Authorization: Bearer ${PACT_TOKEN}" "${PACT_BROKER_URL}/pacts/provider/${PACT_PROVIDER}/consumer/${PACT_CONSUMER}/version/${PACT_VERSION}"`
  fi
  get_res_pact_version
  if [[ "${RES_PACT_VERSION}" == "" ]] || ( [[ "${PACT_VERSION}" != "latest" ]] && [[ "${PACT_VERSION}" != "${RES_PACT_VERSION}" ]] ); then
    err "'get' error: ${RES_PACT}"
  fi
}

pact_put() {
  RES_PACT=`curl -s -X PUT -H "Authorization: Bearer ${PACT_TOKEN}" -H "Content-Type: application/json" -d @"${PACT_FILE}" "${PACT_BROKER_URL}/pacts/provider/${PACT_PROVIDER}/consumer/${PACT_CONSUMER}/version/${PACT_VERSION}"`
  get_res_pact_version
  if [[ "${PACT_VERSION}" != "${RES_PACT_VERSION}" ]]; then
    err "'put' error: ${RES_PACT}"
  fi
}

pact_del() {
  RES_PACT=`curl -s -X DELETE -H "Authorization: Bearer ${PACT_TOKEN}" -H "Content-Type: application/json" "${PACT_BROKER_URL}/pacts/provider/${PACT_PROVIDER}/consumer/${PACT_CONSUMER}/version/${PACT_VERSION}"`
  if [[ "${RES_PACT}" != "" ]]; then
    err "'del' error: ${RES_PACT}"
  fi
}

pact_del_user() {
  RES_PACT=`curl -s -X DELETE -H "Authorization: Bearer ${PACT_TOKEN}" -H "Content-Type: application/json" "${PACT_BROKER_URL}/pacticipants/${PACT_USER}"`
  if [[ "${RES_PACT}" != "" ]]; then
    err "'del_user' error: ${RES_PACT}"
  fi
}

set_depth() {
  if [[ "${ARG_DEPTH}" > "${DEPTH_MAX}" ]] || [[ "${ARG_DEPTH}" < "${DEPTH_MIN}" ]]; then
    ARG_DEPTH=1
  fi
}

set_pact_provider_consumer() {
  if [[ "${ARG_PROVIDER}" == "" ]] || [[ "${ARG_CONSUMER}" == "" ]]; then
    err "'provider' and 'consumer' arguments are required"
  fi
  PACT_PROVIDER="${ARG_PROVIDER}"
  PACT_CONSUMER="${ARG_CONSUMER}"
}

set_pact_version() {
  if [[ "${ARG_VERSION}" == "" ]]; then
   ARG_VERSION=latest
  fi
  PACT_VERSION=${ARG_VERSION}
}

get_res_pact_version() {
  RES_PACT_VERSION=`echo "${RES_PACT}" | jq -r "._links.self.href"`
  RES_PACT_VERSION="${RES_PACT_VERSION##h*\/}"
}

test() {
  DIR_TMP="/tmp/${0##*/}.tmp"
  rm -rf "${DIR_TMP}"
  mkdir "${DIR_TMP}"
  TEST_PROVIDER=TestProvider
  for i in {0..1}; do
    TEST_CONSUMER[${i}]="Test-${RANDOM}-Consumer-${RANDOM}"
    if [ ! -a "${DIR_TMP}/test_pact_${i}.json" ]; then
      cat >"${DIR_TMP}/test_pact_${i}.json" <<__HERE__
{
    "provider": {
        "name": "${TEST_PROVIDER}"
    },
    "consumer": {
        "name": "${TEST_CONSUMER[${i}]}"
    },
    "interactions": [
        {
            "providerState": "test state ${i}",
            "description": "ExampleJavaConsumerPactRuleTest test interaction ${i}",
            "request": {
                "method": "GET",
                "path": "/articles/123${i}",
                "body": null
            },
            "response": {
                "status": 200,
                "body": {
                    "availability": "123${i}",
                    "id": "123${i}",
                    "name": "product123${i}"
                }
            }
        }
    ]
}
__HERE__
    fi
  done
  ARG_DIR="${DIR_TMP}"
  ARG_VERSION=
  put
  echo "Passed 'put' test"
  ARG_CONSUMER="${TEST_CONSUMER[1]}"
  ARG_PROVIDER="${TEST_PROVIDER}"
  ARG_VERSION=
  get > "${DIR_TMP}/test_pact_get.json"
  echo "Passed 'get' test"
  ARG_CONSUMER="${TEST_CONSUMER[1]}"
  ARG_PROVIDER="${TEST_PROVIDER}"
  del
  echo "Passed 'del' test"
  ARG_CONSUMER=
  ARG_PROVIDER=
  ARG_USER=${TEST_CONSUMER[0]}
  ARG_TEST=1
  del_user
  echo "Passed 'del_user' test"
  rm -rf "${DIR_TMP}"
  echo "All tests passed"
}

get() {
  set_pact_provider_consumer
  set_pact_version
  pact_get
  echo "${RES_PACT}"
}

put() {
  if [[ "${ARG_DIR}" == "" ]]; then
    ARG_DIR="${ARG_DIR_DEFAULT}"
  fi
  if [ ! -d "${ARG_DIR}" ]; then
    err "Unable to access dir: '${ARG_DIR}'"
  fi
  set_depth
  PROCESSED=0
  PACT_VERSION="${DATETIME}"
  for FILE in `find "${ARG_DIR}" -maxdepth ${ARG_DEPTH} -type f -path "*.json" 2>/dev/null`; do
    echo "Processing '${FILE}'..."
    ((PROCESSED+=1))
    read PACT_PROVIDER PACT_CONSUMER <<< `jq -r ".provider.name, .consumer.name" "${FILE}"`
    PACT_FILE="${FILE}"
    if [[ "${PACT_PROVIDER}" == "" ]] || [[ "${PACT_CONSUMER}" == "" ]]; then
      err "Error in '${FILE}': a Pact must contain 'provider' and 'consumer' entries"
    fi
    pact_put
    if [[ "${READ_CHECK}" == "1" ]]; then
      pact_get
    fi
  done
  if [[ "${PROCESSED}" == "0" ]]; then
    err "Unable to find any *.json files in folder \"${PACTS_ROOT_DIR}\" with depth=${ARG_DEPTH}"
  fi
  echo -e "Processed ${PROCESSED} files"
}

del() {
  set_pact_provider_consumer
  set_pact_version
  if [[ "${PACT_VERSION}" == "latest" ]]; then
    pact_get
    PACT_VERSION=${RES_PACT_VERSION}
  fi
  pact_del
}

del_user() {
  if [[ "${ARG_USER}" == "" ]]; then
    err "Please provide a \"user\" argument"
  fi
  PACT_USER=${ARG_USER}
  if [[ "${ARG_TEST}" != "1" ]]; then
    echo "This will delete all Pacts associated with ${PACT_USER}. Do you want to proceed? (Y/N)"
    read INPUT
    if [[ "${INPUT}" != "Y" ]] && [[ "${INPUT}" != "y" ]]; then
      err "Aborting..."
    fi
  fi
  pact_del_user
}

shopt -s extglob
PATTERN="+(${MODES})"
for i in "$@"; do
  case "${i}" in ${PATTERN})
    ARG_MODE="${i}"
    ;;
    --dir=*)
    ARG_DIR="${i#*=}"
    ;;
    --depth=*)
    ARG_DEPTH="${i#*=}"
    ;;
    --provider=*)
    ARG_PROVIDER="${i#*=}"
    ;;
    --consumer=*)
    ARG_CONSUMER="${i#*=}"
    ;;
    --user=*)
    ARG_USER="${i#*=}"
    ;;
    --version=*)
    ARG_VERSION="${i#*=}"
    ;;
    *)
    ;;
  esac
done

if [[ "${ARG_MODE}" == "" ]]; then
  err "Mode can be one of: ${MODES}"
fi

echo "Running ${0##*/} ${ARG_MODE}"
token_get
${ARG_MODE}
echo OK
#__EOF__
#bash pacts_upload.sh test
