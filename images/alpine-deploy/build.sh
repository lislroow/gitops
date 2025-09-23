#!/bin/bash

BASEDIR=$( cd "$( dirname "$0" )" && pwd -P )
IMAGE_NAME="devops/alpine-deploy:1.0"
REGISTRY="docker.mgkim.net:5000"

echo "build ${IMAGE_NAME}"

docker build -t ${REGISTRY}/${IMAGE_NAME} .
docker push ${REGISTRY}/${IMAGE_NAME}
