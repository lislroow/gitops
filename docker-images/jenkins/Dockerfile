FROM jenkins/jenkins:2.496-jdk17
USER jenkins
RUN mkdir -p ~/.ssh && \
    ssh-keyscan github.com > ~/.ssh/known_hosts && \
    chmod 600 ~/.ssh/known_hosts
COPY id_ed25519 ~/.ssh/id_ed25519
