FROM amazoncorretto:17-alpine3.20
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
COPY ./scouter.agent /app/scouter
ENV LANG=ko_KR.UTF-8 \
    LC_ALL=ko_KR.UTF-8 \
    TZ=Asia/Seoul
RUN apk add --no-cache \
    vim \
    curl
