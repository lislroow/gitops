#!/bin/bash

BASEDIR=$( cd "$( dirname "$0" )" && pwd -P )
IMAGE_NAME="mgkim/amazoncorretto:8-alpine-jdk-docker"
REGISTRY="docker.mgkim.net:5000"

echo "build ${IMAGE_NAME}"

docker build -t ${REGISTRY}/${IMAGE_NAME} .
docker push ${REGISTRY}/${IMAGE_NAME}
