FROM jenkins/jenkins:2.496-jdk17
USER root
RUN mkdir -p /var/jenkins_home/.ssh && \
    ssh-keyscan github.com > /var/jenkins_home/.ssh/known_hosts && \
    chmod 600 /var/jenkins_home/.ssh/known_hosts
COPY id_ed25519 /var/jenkins_home/.ssh/id_ed25519
RUN chown -R jenkins:jenkins /var/jenkins_home/.ssh
USER jenkins
