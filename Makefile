include .env
# Note STAGE can be "live" or "test" and when empty it has the same
# effect as `include .env` as the first line in this script
include $(STAGE).env

# default executed task when no name is provided
default: none

test:
	./script/gen-scm-source.sh
	cd pact_broker && bundle install && cd ..
	@docker stop ${PSQL_CONT_NAME} || true
	@docker rm ${PSQL_CONT_NAME} || true
	./script/test.sh

build:
	./script/gen-scm-source.sh
	@cd pact_broker && bundle install
	docker build -t pacts:latest .

tag: checkIMG_TAG
	git tag ${IMG_TAG}
	git push
	git push --tags
	docker tag pacts:latest ${REG}/tip/pacts:${IMG_TAG}

push:
	pierone login --url ${REG} --user ${MYUSER}
	docker push ${REG}/tip/pacts:${IMG_TAG}

kio_create:
	@if kio ver show ${APPLICATION_ID} $(APP_VER) >/dev/null 2>&1; then \
	  echo "App ${APPLICATION_ID} version $(APP_VER) already in Kio!"; fi
	@if ! kio ver show ${APPLICATION_ID} $(APP_VER) >/dev/null 2>&1; then \
	  USER=${MYUSER} kio ver create ${APPLICATION_ID} $(APP_VER) docker://${REG}/tip/pacts:${IMG_TAG}; fi

approve:
	USER=${MYUSER} kio ver approve ${APPLICATION_ID} $(APP_VER)

# Note you can also use or export env var `AWS_DEFAULT_REGION` instead of `--region`
senza_create: checkSTAGE
	@echo "Will work on AWS_ACC_NAME='${AWS_ACC_NAME}'"
	@mai login ${AWS_ACC_NAME}-PowerUser
	@pierone login --url ${REG} --user ${MYUSER}
	senza create --region ${AWS_REGION} pacts.yaml ${APP_VER} \
	  ImgTag="${IMG_TAG}" \
	  InstanceType="${INSTANCE_TYPE}" \
	  AWSAccountNum="${AWS_ACC_NUM}" \
	  AWSRegion="${AWS_REGION}" \
	  AWSMintRegion="${AWS_MINT_REGION}" \
	  ApplicationId="${APPLICATION_ID}" \
	  ScalyrKey="${SCALYR_KEY}" \
	  Stage="${STAGE}"
	senza wait --region ${AWS_REGION} pacts ${APP_VER} || true
	senza console --region ${AWS_REGION} --limit 300 pacts ${APP_VER} | grep -iE "error|warn|failed|SUCCESS"

# Validations
checkIMG_TAG:
ifndef IMG_TAG
	$(error IMG_TAG is not set)
endif

checkSTAGE:
ifndef STAGE
	$(error STAGE is not set)
endif
	@if [ "${STAGE}" != "live" ] && [ "${STAGE}" != "test" ]; then \
	  echo "Env var STAGE=$(STAGE) should be 'live' or 'test'"; exit 1; fi

# `make` won't execute a task if there is an existing file with that task name
# so .PHONY is used to skip that logic for the listed task names
.PHONY: \
	checkSTAGE \
	checkIMG_TAG \
	build \
	tag \
	push \
	kio_create \
	approve \
	senza_create \
	test
