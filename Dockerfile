ARG BASE_IMAGE=golang:alpine

FROM ${BASE_IMAGE}

RUN apk update && apk add \
    git \
    bash \
    openssh \
	&& rm -rf /var/cache/apk/*

# install python3 and awscli
RUN echo "**** install Python ****" \
    && apk add --no-cache python3 \
    && if [ ! -e /usr/bin/python ]; then ln -sf python3 /usr/bin/python ; fi  \
    \
    && echo "**** install pip ****" \
    && python3 -m ensurepip \
    && rm -r /usr/lib/python*/ensurepip \
    && pip3 install --no-cache --upgrade pip setuptools wheel \
    && pip3 install awscli

# install terraform
ENV TF_DEV=true
ENV TF_RELEASE=true
ARG TERRAFORM_VERSION=0.12.24

WORKDIR $GOPATH/src/github.com/hashicorp/terraform
RUN git clone https://github.com/hashicorp/terraform.git ./ \
    && git checkout v${TERRAFORM_VERSION} \
    && /bin/bash scripts/build.sh

WORKDIR $GOPATH



