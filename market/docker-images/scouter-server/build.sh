#!/bin/bash

BASE_DIR=$( cd $( dirname $0 ) && pwd -P )
IMAGE_NAME="scouter-server:latest"
REGISTRY="localhost:5000"

echo "build ${IMAGE_NAME}"

docker build -t ${IMAGE_NAME} .
docker image tag ${IMAGE_NAME} market/${IMAGE_NAME}
docker push ${REGISTRY}/market/${IMAGE_NAME}
