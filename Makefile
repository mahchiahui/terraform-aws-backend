# -----------------------------------------------------------------------------
# Terraform Mandatory Environment Variables
# -----------------------------------------------------------------------------

ifndef AWS_ACCESS_KEY_ID
$(error AWS_ACCESS_KEY_ID is not defined, please set it as an environment variable before proceeding)
endif

ifndef AWS_SECRET_ACCESS_KEY
$(error AWS_SECRET_ACCESS_KEY is not defined, please set it as an environment variable before proceeding)
endif

ifndef TF_VAR_S3_BUCKET_NAME
$(error TF_VAR_S3_BUCKET_NAME is not defined, please set it as an environment variable before proceeding)
endif

ifndef TF_VAR_S3_ENC
$(error TF_VAR_S3_ENC is not defined, please set it as an environment variable before proceeding)
endif

ifndef TF_VAR_S3_VER
$(error TF_VAR_S3_VER is not defined, please set it as an environment variable before proceeding)
endif

ifndef TF_VAR_DYNAMODB_TABLE_NAME
$(error TF_VAR_DYNAMODB_TABLE_NAME is not defined, please set it as an environment variable before proceeding)
endif

ifndef TF_VAR_REGION
$(error TF_VAR_REGION is not defined, please set it as an environment variable before proceeding)
endif

ifndef TF_VAR_BACKEND_ENC
$(error TF_VAR_REGION is not defined, please set it as an environment variable before proceeding)
endif

ifndef TF_VAR_TERRAFORM_STATE_FILE
$(error TF_VAR_TERRAFORM_STATE_FILE is not defined, please set it as an environment variable before proceeding)
endif

# -----------------------------------------------------------------------------
# Terraform helper targets
# -----------------------------------------------------------------------------

.PHONY: change-to-local change-to-s3 create-beconf fetch-statefile clean

change-to-local:
	@export BACKEND_TYPE=local; envsubst < templates/template.backend > backend.tf

change-to-s3:
	@export BACKEND_TYPE=s3; envsubst < templates/template.backend > backend.tf

create-beconf:
	@envsubst < templates/template.beconf > beconf.tfvars

clean:
	@rm -rf .terraform
	@rm -rf .terraform.d
	@rm -rf beconf.tfvars
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
	-backend-config=beconf.tfvars
	@rm -rf terraform.tfstate terraform.tfstate.backup backend.tf beconf.tfvars

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
	docker run -it --rm -v $(PWD):/root terraform-aws-backend bash

create-backend:init apply change-to-s3 create-beconf init-backend

destroy-backend:change-to-local init destroy clean

# -----------------------------------------------------------------------------
# Information from git.
# -----------------------------------------------------------------------------

GIT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
GIT_REPOSITORY_NAME := $(shell basename `git rev-parse --show-toplevel`)
GIT_SHA := $(shell git log --pretty=format:'%H' -n 1)
GIT_TAG ?= $(shell git describe --always --tags | awk -F "-" '{print $$1}')
GIT_TAG_END ?= HEAD
GIT_VERSION := $(shell git describe --always --tags --long --dirty | sed -e 's/\-0//' -e 's/\-g.......//')
GIT_VERSION_LONG := $(shell git describe --always --tags --long --dirty)

# -----------------------------------------------------------------------------
# Docker Variables
# -----------------------------------------------------------------------------

BASE_IMAGE ?= golang:alpine
TERRAFORM_VERSION ?= 0.12.24
DOCKER_IMAGE_PACKAGE := $(GIT_REPOSITORY_NAME)-package:$(GIT_VERSION)
DOCKER_IMAGE_TAG ?= $(GIT_REPOSITORY_NAME):$(GIT_VERSION)
DOCKER_IMAGE_NAME := $(GIT_REPOSITORY_NAME)


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
