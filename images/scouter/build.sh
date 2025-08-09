#!/bin/bash

BASEDIR=$( cd "$( dirname "$0" )" && pwd -P )
IMAGE_NAME="study/scouter:1.0"
REGISTRY="localhost:5000"

echo "build ${IMAGE_NAME}"

docker build -t ${REGISTRY}/${IMAGE_NAME} .
docker push ${REGISTRY}/${IMAGE_NAME}
