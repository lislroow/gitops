#!/bin/bash

cd ~/docker/market && \
docker rm -f redis; \
docker-compose -f redis.yml create; \
docker start redis
