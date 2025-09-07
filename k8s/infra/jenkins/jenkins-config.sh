kubectl create deployment jenkins \
  --image=jenkins/jenkins:lts-jdk17 \
  --port=8080