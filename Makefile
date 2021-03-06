include .env
# Note STAGE can be "live" or "test" and when empty it has the same
# effect as `include .env` as the first line in this script
include $(STAGE).env

# default executed task when no name is provided
default: none

env:
	env

test:
	./script/gen-scm-source.sh
	cd pact_broker && bundle install && cd ..
	@docker stop ${PSQL_CONT_NAME} || true
	@docker rm ${PSQL_CONT_NAME} || true
	./script/test.sh

tag: checkIMG_TAG
	git tag ${IMG_TAG}
	git push
	git push --tags

build: checkIMG_TAG
	./script/gen-scm-source.sh
	@cd pact_broker && bundle install
	docker build -t pacts:latest .
	docker tag pacts:latest ${REG}/tip/pacts:${IMG_TAG}

login:
	pierone login && zaws login ${AWS_ACC_NAME} PowerUser

push: login
	docker push ${REG}/tip/pacts:${IMG_TAG}

kio_create:
	@if kio version show ${APPLICATION_ID} $(APP_VER) >/dev/null 2>&1; then \
	  echo "App ${APPLICATION_ID} version $(APP_VER) already in Kio!"; fi
	if ! kio version show ${APPLICATION_ID} $(APP_VER) >/dev/null 2>&1; then \
	  USER=${MYUSER} kio version create ${APPLICATION_ID} $(APP_VER) docker://${REG}/tip/pacts:${IMG_TAG}; fi

approve:
	USER=${MYUSER} kio version approve ${APPLICATION_ID} $(APP_VER)

# Note you can also use or export env var `AWS_DEFAULT_REGION` instead of `--region`
senza_create: checkSTAGE login
	@echo "Will work on AWS_ACC_NAME='${AWS_ACC_NAME}'"
	senza create --region ${AWS_REGION} --parameter-file ${STAGE}.yaml \
	  pacts.yaml ${APP_VER} ImgTag="${IMG_TAG}"
	senza wait --region ${AWS_REGION} pacts ${APP_VER} || true
	senza console --region ${AWS_REGION} --limit 300 pacts ${APP_VER} | grep -iE "error|warn|failed" || true

senza_traffic: checkSTAGE login
	@echo "Will update traffic on AWS_ACC_NAME='${AWS_ACC_NAME}'"
	senza traffic --region ${AWS_REGION} pacts ${APP_VER} 100

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

# PHONY: Given make doesn't execute a task if there is an existing file
# with that task name, .PHONY is used to skip that logic listing task names
.PHONY: \
	checkSTAGE \
	checkIMG_TAG \
	build \
	tag \
	push \
	kio_create \
	approve \
	senza_create \
	env \
	test
