include .env
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

create: checkSTAGE
	@echo "Will work on AWS_ACC_NAME='${AWS_ACC_NAME}'"
	@mai login ${AWS_ACC_NAME}-PowerUser
	senza create pacts.yaml ${APP_VER} \
	  ImgTag="${IMG_TAG}" \
	  InstanceType="${INSTANCE_TYPE}" \
	  AWSAccountNum="${AWS_ACC_NUM}" \
	  ApplicationId="${APPLICATION_ID}" \
	  Stage="${STAGE}"
	senza wait pacts ${APP_VER}
	senza console --limit 300 pacts ${APP_VER} | grep -iE "error|warn|failed"

approve:
	export USER=$(MYUSER)
	kio ver create pacts $(APP_VER) docker://${REG}/tip/pacts:${IMG_TAG}
	kio ver approve pacts $(APP_VER)

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
	build \
	tag \
	push \
	create \
	test
