#!/bin/bash

BASE_DIR=$( cd $( dirname $0 ) && pwd -P )
IMAGE_NAME="market/scouter-server:latest"
REGISTRY="localhost:5000"

echo "build ${IMAGE_NAME}"

docker build -t ${REGISTRY}/${IMAGE_NAME} .
docker image tag ${IMAGE_NAME} ${IMAGE_NAME}
docker push ${REGISTRY}/${IMAGE_NAME}
