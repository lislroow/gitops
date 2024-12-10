FROM amazoncorretto:8-alpine-jdk
RUN apk add --no-cache \
    tzdata \
    bash \
    openrc \
    && apk add --no-cache --virtual .locale-build-deps \
    musl-locales \
    musl-locales-lang \
    && cp /usr/share/zoneinfo/Asia/Seoul /etc/localtime \
    && echo "Asia/Seoul" > /etc/timezone \
    && echo "ko_KR.UTF-8 UTF-8" > /etc/locale.gen \
    && echo "LANG=ko_KR.UTF-8" > /etc/locale.conf \
    && apk del .locale-build-deps
ENV LANG=ko_KR.UTF-8 \
    LC_ALL=ko_KR.UTF-8 \
    TZ=Asia/Seoul
EXPOSE 6100/tcp
EXPOSE 6100/udp
WORKDIR /app
COPY ./app /app
ENTRYPOINT ["/bin/bash", "-c", "pwd && ls -al && ./start-scouter.sh"]