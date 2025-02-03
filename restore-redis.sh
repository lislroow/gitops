#!/bin/bash

cd ~/docker/market && \
docker rm -f redis; \
docker-compose -f redis.yml create; \
docker cp ~/redis-dump/dump.rdb redis:/data; \
docker start redis

docker stats
