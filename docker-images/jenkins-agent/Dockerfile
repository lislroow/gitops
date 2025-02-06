FROM jenkins/ssh-agent:alpine-jdk17
RUN apk add --no-cache \
    tzdata \
    bash \
    openrc \
    curl \
    && apk add --no-cache --virtual .locale-build-deps \
    musl-locales \
    musl-locales-lang \
    && cp /usr/share/zoneinfo/Asia/Seoul /etc/localtime \
    && echo "Asia/Seoul" > /etc/timezone \
    && echo "ko_KR.UTF-8 UTF-8" > /etc/locale.gen \
    && echo "LANG=ko_KR.UTF-8" > /etc/locale.conf \
    && apk del .locale-build-deps
RUN mkdir -p /home/jenkins/.ssh && \
    ssh-keyscan github.com > /home/jenkins/.ssh/known_hosts && \
    chmod 600 /home/jenkins/.ssh/known_hosts
RUN curl -sOL https://corretto.aws/downloads/latest/amazon-corretto-17-x64-alpine-jdk.tar.gz && \
    mkdir -p /home/jenkins/corretto-17 && \
    tar zxvf amazon-corretto-17-x64-alpine-jdk.tar.gz --strip-components=1 -C /home/jenkins/corretto-17 && \
    chown -R jenkins:jenkins /home/jenkins/corretto-17 && \
    rm -rf amazon-corretto-17-x64-alpine-jdk.tar.gz
ENV JAVA_HOME=/home/jenkins/corretto-17
ENV PATH=$JAVA_HOME/bin:$PATH
COPY id_ed25519 /home/jenkins/.ssh/id_ed25519
RUN chown -R jenkins:jenkins /home/jenkins/.ssh
