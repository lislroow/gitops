#### docker-image in gitlab-runner 

- gitlab-runner 내부에서 docker pull 을 할때 ~/.docker/config.json 에 인증 정보가 없으면 `no basic auth credentials` 가 발생함

```yml
services:
  gitlab-runner:
    image: gitlab/gitlab-runner:alpine-v17.4.2
    volumes:
      - /root/.docker/config.json:/root/.docker/config.json
```

#### gitlab-runner register

- GitLab 17.x에서는 Runner registration token이 곧 폐지(deprecated) 될 예정
- [X] Admin Area > Settings > Access Tokens에서 생성, `--token` (Scope: write_registry, read_registry)
- [O] 프로젝트 → Settings > CI/CD > Runners::Registration Token, `--registration-token`
- gitlab 연결 테스트: `docker exec -it gitlab-runner curl -k http://gitlab/` 

```shell
RUNNER_TOKEN="<registration-token>"
docker exec -it gitlab-runner gitlab-runner register \
  --non-interactive \
  --url "http://gitlab/" \
  --registration-token "$RUNNER_TOKEN" \
  --executor "docker" \
  --docker-image amazoncorretto:17-alpine-jdk \
  --tag-list "java17"

docker exec -it gitlab-runner gitlab-runner register \
  --non-interactive \
  --url "http://gitlab/" \
  --registration-token "$RUNNER_TOKEN" \
  --executor "docker" \
  --docker-image amazoncorretto:8-alpine-jdk \
  --tag-list "java8"

docker exec -it gitlab-runner gitlab-runner register \
  --non-interactive \
  --url "http://gitlab/" \
  --registration-token "$RUNNER_TOKEN" \
  --executor "docker" \
  --docker-image docker.mgkim.net:5000/devops/alpine-deploy:1.0 \
  --tag-list "deploy"

cat /var/lib/docker/volumes/devops_gitlab-runner_conf/_data/config.toml
```

#### gitlab-runner configuration

- `8093:8093` 을 expose 하는 것은 session_server 를 사용할 때 필요함

```yml
port:
  - 8093:8093
```
