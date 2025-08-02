FROM amazoncorretto:17-alpine-jdk
RUN apk add --no-cache docker
RUN apk add --no-cache bash curl
RUN mkdir /root/.docker && echo '{"auths": {"docker.mgkim.net:5000": {"auth": "YWRtaW46MQ=="}}}' > /root/.docker/config.json
