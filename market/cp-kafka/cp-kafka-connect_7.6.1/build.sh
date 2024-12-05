#!/bin/bash

BASE_DIR=$( cd $( dirname $0 ) && pwd -P )
IMAGE_NAME="market/cp-kafka-connect:7.6.1"
REGISTRY="docker.mgkim.net:5000"

echo "build ${IMAGE_NAME}"

docker build -t ${REGISTRY}/${IMAGE_NAME} .
docker push ${REGISTRY}/${IMAGE_NAME}
