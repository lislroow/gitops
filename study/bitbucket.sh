if [ $(docker volume ls | grep -c bitbucket_data) -eq 0 ]; then
  docker volume create --name bitbucket_data
fi

docker run -v bitbucket_data:/var/atlassian/application-data/bitbucket --name="bitbucket" -d -p 7990:7990 -p 7999:7999 atlassian/bitbucket:8.16.3-jdk17
