FROM amazoncorretto:8-alpine-jdk
EXPOSE 6100/tcp
EXPOSE 6180/tcp
EXPOSE 6100/udp
WORKDIR /app
COPY ./app /app
ENTRYPOINT ["/bin/sh", "-c", "pwd && ls -al && \
  java -Xmx1024m -classpath ./scouter-server-boot.jar \
       scouter.boot.Boot ./lib"]