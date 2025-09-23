FROM amazoncorretto:8u462-al2023
ENV LANG=ko_KR.UTF-8 \
    LC_ALL=ko_KR.UTF-8 \
    TZ=Asia/Seoul
EXPOSE 6100/tcp
EXPOSE 6100/udp
WORKDIR /app
USER root
COPY ./app /app
RUN mkdir /data
RUN mkdir /logs
USER root
ENTRYPOINT ["/bin/bash", "-c", "/app/server.sh start"]
