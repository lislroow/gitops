FROM jenkins/jenkins:2.496-jdk17
RUN mkdir -p ~jenkins/.ssh && \
    ssh-keyscan github.com > ~jenkins/.ssh/known_hosts && \
    chmod 600 ~jenkins/.ssh/known_hosts
COPY id_ed25519 ~jenkins/.ssh/id_ed25519
RUN chown -R jenkins:jenkins ~jenkins/.ssh

USER jenkins
