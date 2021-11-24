.PHONY: *
.ONESHELL:
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
MAKEFLAGS += --warn-undefined-variables

PROJECT_NAME=$(shell pwd | rev | cut -d/ -f1 | rev)
PORT=8080

SERVICE_ACCOUNT=cr-jobstatus-dashboard@siapi-262514.iam.gserviceaccount.com
# GOOGLE_APPLICATION_CREDENTIALS=$(shell pwd)/.gcpconf/account.json
PROD=false
# DOCKERFILE=$(shell [[ $(PROD) == 'true' ]] && echo 'Dockerfile' || echo 'Dockerfile.dev')
DOCKERFILE=Dockerfile

default: kill build run ps
	@echo tag is "'"$(PROJECT_NAME)"'"

raw-run:
	cd src && python -c 'import main; main.app.run(port=8080)'

rr: raw-run

lock:
	piplock requirements.txt | tee /dev/tty 1> requirements.lock

# Docker related v

build:
	docker build . \
	-f $(DOCKERFILE) \
	-t $(PROJECT_NAME)

run:
	docker run -d \
	-p $(PORT):8080 \
	--network="host" \
	-e GOOGLE_APPLICATION_CREDENTIALS=$(GOOGLE_APPLICATION_CREDENTIALS) \
	--mount type=bind,source=$$(dirname $(GOOGLE_APPLICATION_CREDENTIALS)),target=$$(dirname $(GOOGLE_APPLICATION_CREDENTIALS)) \
	$(PROJECT_NAME)


kill:
	set +o pipefail
	docker ps | grep -w $(PROJECT_NAME) | cut -d' ' -f1 | xargs -r docker kill

rm:
	set +o pipefail
	docker ps -a | grep -w $(PROJECT_NAME) | cut -d' ' -f1 | xargs -r docker rm

logs:
	set +o pipefail
	docker ps -a | grep -w $(PROJECT_NAME) | head -n 1 | cut -d' ' -f1 | xargs -r docker logs

ll:
	make logs 2>&1 | less +G -r

ps:
	docker ps | grep -w $(PROJECT_NAME)

watch:
	watch --color -n .2 "make -s l 2>&1 | tail -n $$(($$(tput lines) - 3))"

dev:
	make && make watch

b: build
r: run
ri: run-it
k: kill
l: logs
p: ps
w: watch
d: dev

# Git repo

REMOTE=origin

print-repo:
	@
	remote=$$(git remote get-url $(REMOTE) 2>&1)
	echo $$remote | grep ^http 1> /dev/null || remote=https://$$(echo $$remote | cut -d@ -f2 | tr ':' '/')
	echo $$remote

repo:
	xdg-open $$(make -s print-repo)

repo.%: 
	@make -s repo REMOTE=$*

# GCP Credentials

init:
	@
	mkdir -p .gcpconf
	[ -f .gcpconf/account.json ] || \
	gcloud iam service-accounts keys create \
	--iam-account=$(SERVICE_ACCOUNT) \
	--key-file-type=json \
	.gcpconf/account.json
	[ ! -f .gitignore ] || [ ! `grep -w ".gcpconf" .gitignore` ] && printf "\n.gcpconf" >> .gitignore || exit 0


# Deploy to Cloud Run

CONTAINER_REGISTRY=eu.gcr.io
GCP_PROJECT_ID=siapi-262514
SALT=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 13)

deploy:
	# build image
	make build PROJECT_NAME="$(CONTAINER_REGISTRY)/$(GCP_PROJECT_ID)/$(PROJECT_NAME)"

	# push image to $(CONTAINER_REGISTRY)
	gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin https://$(CONTAINER_REGISTRY)
	
	# echo Press Enter
	# read -r
	
	docker push $(CONTAINER_REGISTRY)/$(GCP_PROJECT_ID)/$(PROJECT_NAME)
	
	# deploy image to cloud run
	gcloud run deploy $(PROJECT_NAME) \
	--image $(CONTAINER_REGISTRY)/$(GCP_PROJECT_ID)/$(PROJECT_NAME) \
	--platform managed \
	--region europe-west1 \
	--allow-unauthenticated
