#### deploy with ssh

```shell
# gitlab-runner
ssh-keygen -t rsa -b 4096 -C "gitlab-runner" -f ~/.ssh/id_rsa

# deploy-server
echo "<~/.ssh/id_rsa>" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```


#### docker-image in gitlab-runner 

- gitlab-runner 내부에서 docker pull 을 할때 ~/.docker/config.json 에 인증 정보가 없으면 `no basic auth credentials` 가 발생함

```yml
services:
  gitlab-runner:
    image: gitlab/gitlab-runner:alpine-v17.4.2
    volumes:
      - /root/.docker/config.json:/root/.docker/config.json
```

#### gitlab-runner concurrent

- `concurrent = 2`

```toml
# [root@rocky8-devops ~]# cat /var/lib/docker/volumes/devops_gitlab-runner_conf/_data/config.toml 
# concurrent = 1
concurrent = 2
check_interval = 0
connection_max_age = "15m0s"
shutdown_timeout = 0
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
  --url "https://gitlab.mgkim.net/" \
  --registration-token "$RUNNER_TOKEN" \
  --executor "docker" \
  --docker-image docker.mgkim.net:5000/mgkim/amazoncorretto:17-alpine-jdk-docker \
  --tag-list "java17"

docker exec -it gitlab-runner gitlab-runner register \
  --non-interactive \
  --url "https://gitlab.mgkim.net/" \
  --registration-token "$RUNNER_TOKEN" \
  --executor "docker" \
  --docker-image docker.mgkim.net:5000/mgkim/amazoncorretto:8-alpine-jdk-docker \
  --tag-list "java8"

docker exec -it gitlab-runner gitlab-runner register \
  --non-interactive \
  --url "https://gitlab.mgkim.net/" \
  --registration-token "$RUNNER_TOKEN" \
  --executor "docker" \
  --docker-image docker.mgkim.net:5000/devops/alpine-deploy:1.0 \
  --tag-list "deploy" \
  --docker-volumes "/var/run/docker.sock:/var/run/docker.sock" \
  --docker-volumes "/root/.ssh/id_rsa:/root/.ssh/id_rsa:ro"

cat /var/lib/docker/volumes/devops_gitlab-runner_conf/_data/config.toml

concurrent = 3
check_interval = 0
connection_max_age = "15m0s"
shutdown_timeout = 0

[session_server]
  session_timeout = 1800

[[runners]]
  name = "6fda0f509845"
  url = "https://gitlab.mgkim.net/"
  id = 9
  token = "ATsXj13a5Lx7ybjgb2nG"
  token_obtained_at = 2024-12-07T14:26:43Z
  token_expires_at = 0001-01-01T00:00:00Z
  executor = "docker"
  [runners.custom_build_dir]
  [runners.cache]
    MaxUploadedArchiveSize = 0
    [runners.cache.s3]
    [runners.cache.gcs]
    [runners.cache.azure]
  [runners.docker]
    tls_verify = false
    image = "docker.mgkim.net:5000/devops/alpine-deploy:1.0"
    privileged = false
    disable_entrypoint_overwrite = false
    oom_kill_disable = false
    disable_cache = false
    volumes = ["/cache"]
    shm_size = 0
    network_mtu = 0
```

#### gitlab-runner configuration

- `8093:8093` 을 expose 하는 것은 session_server 를 사용할 때 필요함

```yml
port:
  - 8093:8093
```
