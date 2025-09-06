if [ $(docker volume ls | grep -c bamboo_data) -eq 0 ]; then
  docker volume create --name bamboo_data
fi

docker run -v bamboo_data:/var/atlassian/application-data/bamboo --name="bamboo" -d -p 8085:8085 -p 54663:54663 atlassian/bamboo:9.6-jdk17
