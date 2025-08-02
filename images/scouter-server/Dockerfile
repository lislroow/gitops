FROM amazoncorretto:8u462-al2023
ENV LANG=ko_KR.UTF-8 \
    LC_ALL=ko_KR.UTF-8 \
    TZ=Asia/Seoul
EXPOSE 6100/tcp
EXPOSE 6100/udp
WORKDIR /app
COPY ./app /app
RUN apk add --no-cache dos2unix file
RUN /app/start-scouter.sh
RUN /app/start-scouter.sh
ENTRYPOINT ["/bin/bash", "-c", "pwd && ls -al && /app/start-scouter.sh"]
