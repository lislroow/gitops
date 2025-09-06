#!/bin/sh

echo "[docker] stop scouter"

docker ps -a --filter "name=^scouter" --format "{{.ID}}" | xargs -r docker rm -f


echo "[docker] start scouter"

docker run -d \
  --name "scouter" \
  --hostname "scouter" \
  -p 6100:6100 \
  -p 6100:6100/udp \
  -v scouter_data:/app/data \
  -e SC_SERVER_ID=SCCOUTER-COLLECTOR \
  -e NET_HTTP_SERVER_ENABLED=true \
  -e NET_HTTP_API_SWAGGER_ENABLED=true \
  -e NET_HTTP_API_ENABLED=true \
  -e MGR_PURGE_PROFILE_KEEP_DAYS=2 \
  -e MGR_PURGE_XLOG_KEEP_DAYS=2 \
  -e MGR_PURGE_COUNTER_KEEP_DAYS=2 \
  -e JAVA_OPT="-Xms512m -Xmx512m" \
  "172.28.200.101:5000/study/scouter:1.0"
