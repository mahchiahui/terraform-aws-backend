# -----------------------------------------------------------------------------
# Terraform Mandatory Environment Variables
# -----------------------------------------------------------------------------

# check if the following variables are set, if not set, fail
ifndef AWS_ACCESS_KEY_ID
$(error TF_VAR_region is not defined, please set it as an environment variable before proceeding)
endif

ifndef AWS_SECRET_ACCESS_KEY
$(error TF_VAR_region is not defined, please set it as an environment variable before proceeding)
endif

# -----------------------------------------------------------------------------
# Terraform targets
# -----------------------------------------------------------------------------

.PHONY: init init-backend update plan apply format clean cli create-backend destroy-backend
init:
	-terraform init \
	-force-copy \
	-input=false \
	-upgrade

init-backend:
	-terraform init \
	-force-copy \
	-input=false \
	-backend-config=beconf.tfvars

update:
	terraform get -update

plan:
	terraform plan \
	-input=false \
	-refresh=true

apply:
	-terraform apply \
	-input=false \
	-auto-approve

format:
	terraform fmt

destroy:
	terraform destroy -auto-approve -input=false

clean:
	@rm -rf .terraform
	@rm -rf .terraform.d
	@rm -rf *.terraform.tfstate
	@rm -rf errored.tfstate
	@rm -rf crash.log

cli:
	@docker run -it --rm -v $(PWD):/root terrafrom-aws bash

create-backend:init apply init-backend

destroy-backend: destroy clean


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
