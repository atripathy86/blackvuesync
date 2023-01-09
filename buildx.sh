#!/usr/bin/env bash
#shellcheck shell=bash

REPO=atripathy86
IMAGE=blackvuesync
PLATFORMS="linux/amd64,linux/arm/v6,linux/arm/v7,linux/arm64"
LATEST_TAG=latest

#https://docs.docker.com/buildx/working-with-buildx/
#Building Multi-platform images 
#Supported options are:  "linux/amd64", "linux/arm64", "linux/riscv64","linux/ppc64le","linux/s390x","linux/386","linux/mips64le","linux/mips64","linux/arm/v7","linux/arm/v6"
#Make sure docker buildx is available, else install plugin
if ! docker buildx version ; then 
	mkdir -p ~/.docker/cli-plugins
	if [ `uname -m` == 'x86_64' ] ; then
		wget https://github.com/docker/buildx/releases/download/v0.7.1/buildx-v0.7.1.linux-amd64 -O ~/.docker/cli-plugins/docker-buildx
	elif [ `uname -m` == 'armv7l' ] ; then
        	wget https://github.com/docker/buildx/releases/download/v0.7.1/buildx-v0.7.1.linux-arm-v7 -O ~/.docker/cli-plugins/docker-buildx
	elif [ `uname -m` == 'armv6l' ] ; then
		wget https://github.com/docker/buildx/releases/download/v0.7.1/buildx-v0.7.1.linux-arm-v6 -O ~/.docker/cli-plugins/docker-buildx
	elif [ `uname -m` == 'aarch64' ] ; then
                wget https://github.com/docker/buildx/releases/download/v0.7.1/buildx-v0.7.1.linux-arm64 -O ~/.docker/cli-plugins/docker-buildx

	fi

	chmod a+x ~/.docker/cli-plugins/docker-buildx

	sudo docker run --privileged --rm tonistiigi/binfmt --install all
fi


if ! docker buildx use cross-build; then docker buildx create --use --name cross-build; fi
#docker context use x86_64
export DOCKER_CLI_EXPERIMENTAL="enabled"
docker buildx use cross-build

# Build & push latest
EXITCODE=1
FIRSTRUN=1
TRIES=1
while [[ "$EXITCODE" -ne 0 ]]; do
    echo "Attempting build, try $TRIES"
    if [[ "$FIRSTRUN" -eq 1 ]]; then
        docker buildx build --no-cache -t "${REPO}/${IMAGE}:${LATEST_TAG}" --compress --push --platform "${PLATFORMS}" .
        EXITCODE="$?"
        FIRSTRUN=0
    else
        docker buildx build -t "${REPO}/${IMAGE}:${LATEST_TAG}" --compress --push --platform "${PLATFORMS}" .
        EXITCODE="$?"
    fi
    TRIES=$((TRIES+1))
    if [[ "$TRIES" -ge 5 ]]; then
        exit 1
    fi
done

