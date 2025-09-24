#!/bin/bash

BASEDIR=$( cd "$( dirname "$0" )" && pwd -P )
IMAGE_NAME="study/ssh-agent:alpine3.21"
REGISTRY="localhost:5000"

echo "build ${IMAGE_NAME}"

cp /root/.ssh/id_ed25519 .
docker build -t ${REGISTRY}/${IMAGE_NAME} .
rm -rf id_ed25519
docker push ${REGISTRY}/${IMAGE_NAME}
