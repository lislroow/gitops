FROM jenkins/jenkins:2.496-jdk17
USER root
RUN apt-get update && \
    apt-get install -y podman&& \
   # rootless 환경 설정을 위한 준비
   mkdir -p /home/jenkins/.config/containers && \
   chown -R jenkins:jenkins /home/jenkins/.config

USER jenkins

# Podman을 rootless로 사용하기 위한 환경변수 설정
ENV XDG_RUNTIME_DIR=/home/jenkins/.podman
ENV PATH=$PATH:/usr/bin/podman
