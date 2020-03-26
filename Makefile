# check if the following variables are set, if not set, fail
ifndef TF_VAR_s3_bucket_name
$(error TF_VAR_s3_bucket_name is not defined, please set it as an environment variable before proceeding)
endif

ifndef TF_VAR_s3_bucket_encryption
$(error TF_VAR_s3_bucket_encryption is not defined, please set it as an environment variable before proceeding)
endif

ifndef TF_VAR_DynamoDB_name
$(error TF_VAR_DynamoDB_name is not defined, please set it as an environment variable before proceeding)
endif

ifndef TF_VAR_region
$(error TF_VAR_region is not defined, please set it as an environment variable before proceeding)
endif

ifndef TF_VAR_backend_key
$(error TF_VAR_region is not defined, please set it as an environment variable before proceeding)
endif

# Terraform targets

.PHONY: init update plan apply
init:
	terraform init \
	-force-copy \
	-input=false \
	-upgrade

update:
	terraform get -update

plan:
	terraform plan \
	-input=false \
	-refresh=true

apply:
	terraform apply \
	-input=false \
	-auto-approve

# Docker variables

GIT_VERSION := $(shell git describe --always --tags --long --dirty | sed -e 's/\-0//' -e 's/\-g.......//')
GIT_REPO_NAME = $(shell basename `git rev-parse --show-toplevel`)
DOCKER_IMAGE_TAG ?= $(GIT_REPO_NAME):$(GIT_VERSION)
BASE_IMAGE ?= golang:alpine
TERRAFORM_VERSION ?= 0.12.24

# Docker targets

.PHONY: docker-build docker-clean
docker-build:
	docker build \
		--build-arg BASE_IMAGE="$(BASE_IMAGE)" \
		--build-arg TERRAFORM_VERSION="$(TERRAFORM_VERSION)" \
		--tag $(DOCKER_IMAGE_TAG) \
		.

docker-clean:
	docker rmi --force $(DOCKER_IMAGE_TAG)