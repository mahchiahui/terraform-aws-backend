# -----------------------------------------------------------------------------
# Terraform Mandatory Environment Variables
# -----------------------------------------------------------------------------

TARGETS_TO_CHECK := "cli init init-backend update plan apply format destroy backend create-backend destroy-backend"

ifeq ($(findstring $(MAKECMDGOALS),$(TARGETS_TO_CHECK)),$(MAKECMDGOALS))
ifndef AWS_ACCESS_KEY_ID
$(error AWS_ACCESS_KEY_ID is not defined, please set it as an environment variable before proceeding)
endif

ifndef AWS_SECRET_ACCESS_KEY
$(error AWS_SECRET_ACCESS_KEY is not defined, please set it as an environment variable before proceeding)
endif

ifndef AWS_DEFAULT_REGION
$(error AWS_DEFAULT_REGION is not defined, please set it as an environment variable before proceeding)
endif
endif

# -----------------------------------------------------------------------------
# Information from git.
# -----------------------------------------------------------------------------

GIT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
GIT_REPOSITORY_NAME := $(shell git config --get remote.origin.url | cut -d'/' -f5 | cut -d'.' -f1)
GIT_ACCOUNT_NAME := $(shell git config --get remote.origin.url | cut -d'/' -f4)
GIT_SHA := $(shell git log --pretty=format:'%H' -n 1)
GIT_TAG ?= $(shell git describe --always --tags | awk -F "-" '{print $$1}')
GIT_TAG_END ?= HEAD
GIT_VERSION := $(shell git describe --always --tags --long --dirty | sed -e 's/\-0//' -e 's/\-g.......//')
GIT_VERSION_LONG := $(shell git describe --always --tags --long --dirty)

# -----------------------------------------------------------------------------
# Docker Variables
# -----------------------------------------------------------------------------

BASE_IMAGE ?= golang:1.14.1-alpine3.11
TERRAFORM_VERSION ?= 0.12.24
DOCKER_IMAGE_PACKAGE := $(GIT_REPOSITORY_NAME)-package:$(GIT_VERSION)
DOCKER_IMAGE_TAG ?= $(GIT_REPOSITORY_NAME):$(GIT_VERSION)
DOCKER_IMAGE_NAME := $(GIT_REPOSITORY_NAME)

# -----------------------------------------------------------------------------
# Terraform variables
# -----------------------------------------------------------------------------

.EXPORT_ALL_VARIABLES:
TF_VAR_s3_bucket_name:= $(GIT_ACCOUNT_NAME)-$(GIT_REPOSITORY_NAME)
TF_VAR_bucket_key := backend/$(GIT_REPOSITORY_NAME).tfstate

# -----------------------------------------------------------------------------
# Terraform helper targets
# -----------------------------------------------------------------------------

.PHONY: change-to-local change-to-s3 fetch-statefile clean

change-to-local:
	@export BACKEND_TYPE=local; \
	export BUCKET=""; \
	export KEY=""; \
	export REGION=""; \
	export DYNAMODB_TABLE=""; \
	export ENCRYPT=""; \
	envsubst < templates/template.backend > backend.tf

change-to-s3:
	@export BACKEND_TYPE=s3; \
	export BUCKET="bucket = \"$(TF_VAR_s3_bucket_name)\""; \
	export KEY="key = \"$(TF_VAR_bucket_key)\""; \
	export REGION="region = \"$(AWS_DEFAULT_REGION)\""; \
	export DYNAMODB_TABLE="dynamodb_table = \"$(TF_VAR_s3_bucket_name)\""; \
	export ENCRYPT="encrypt = \"true\""; \
	envsubst < templates/template.backend > backend.tf

clean:
	@rm -rf .terraform
	@rm -rf .terraform.d
	@rm -rf backend.tf
	@rm -rf terraform.tfstate terraform.tfstate.backup
	@rm -rf errored.tfstate
	@rm -rf crash.log

# -----------------------------------------------------------------------------
# Terraform targets
# -----------------------------------------------------------------------------

.PHONY: init init-backend update plan apply format cli create-backend destroy-backend 
init:
	@terraform init \
	-force-copy \
	-input=false \
	-upgrade

init-backend:
	@terraform init \
	-force-copy \
	-input=false \
	-upgrade
	@rm -rf terraform.tfstate terraform.tfstate.backup backend.tf

update:
	terraform get -update

plan:
	terraform plan \
	-input=false \
	-refresh=true

apply:
	@terraform apply \
	-input=false \
	-auto-approve

format:
	terraform fmt

destroy:
	terraform destroy -auto-approve -input=false

cli:
	docker run \
	-it \
	--rm \
	-v $(PWD):/root \
	--env AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) \
	--env AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY) \
	--env AWS_DEFAULT_REGION=$(AWS_DEFAULT_REGION) \
	$(DOCKER_IMAGE_NAME) \
	bash

create-backend:init apply change-to-s3 init-backend

destroy-backend:change-to-local init destroy clean

# -----------------------------------------------------------------------------
# Docker Build Targets
# -----------------------------------------------------------------------------

.PHONY: docker-build docker-build-development-cache
docker-build:
	docker build \
		--build-arg BASE_IMAGE="$(BASE_IMAGE)" \
		--build-arg TERRAFORM_VERSION="$(TERRAFORM_VERSION)" \
		--tag $(DOCKER_IMAGE_NAME) \
		--tag $(DOCKER_IMAGE_TAG) \
		.

docker-build-development-cache: docker-rmi-for-build-development-cache
	docker build \
		--build-arg BASE_IMAGE=$(BASE_IMAGE) \
		--build-arg GOLANG_VERSION=$(GOLANG_VERSION) \
		--build-arg GOLANG_SHA=$(GOLANG_SHA) \
		--build-arg TERRAFORM_VERSION=$(TERRAFORM_VERSION) \
		--tag $(DOCKER_IMAGE_TAG) \
		.

# -----------------------------------------------------------------------------
# Docker RMI Targets
# -----------------------------------------------------------------------------

.PHONY: docker-rmi-for-build docker-rmi-for-build-development-cache docker-rmi-for-package rm-target docker-clean
docker-rmi-for-build:
	-docker rmi --force \
		$(DOCKER_IMAGE_NAME):$(GIT_VERSION) \
		$(DOCKER_IMAGE_NAME)

docker-rmi-for-build-development-cache:
	-docker rmi --force $(DOCKER_IMAGE_TAG)

docker-rmi-for-package:
	-docker rmi --force $(DOCKER_IMAGE_PACKAGE)

rm-target:
	-rm -rf $(TARGET)

docker-clean: docker-rmi-for-build docker-rmi-for-build-development-cache docker-rmi-for-package rm-target
