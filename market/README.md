- volume 정리

```
# 현재 컨테이너와 연결되지 않은 볼륨 확인
docker volume ls --filter dangling=true

# 사용되지 않는 볼륨 삭제
docker volume prune
```


```bash
#!/bin/bash

unused_volumes=$(docker volume ls --filter dangling=true -q)

if [ -z "$unused_volumes" ]; then
  echo "사용되지 않는 볼륨이 없습니다."
else
  echo "사용되지 않는 볼륨 목록:"
  echo "$unused_volumes"

  read -p "이 볼륨들을 삭제하시겠습니까? (y/n): " confirm
  if [ "$confirm" == "y" ]; then
    docker volume rm $unused_volumes
    echo "사용되지 않는 볼륨이 삭제되었습니다."
  else
    echo "삭제 작업이 취소되었습니다."
  fi
fi
```


- volume inspect

```
# docker volume inspect 231e17d97e86bef139ef430e4f9b94aae0d36c6f1c2f01f0a5531845df80c850
[
    {
        "CreatedAt": "2024-12-02T10:54:56+09:00",
        "Driver": "local",
        "Labels": {
            "com.docker.volume.anonymous": ""
        },
        "Mountpoint": "/var/lib/docker/volumes/231e17d97e86bef139ef430e4f9b94aae0d36c6f1c2f01f0a5531845df80c850/_data",
        "Name": "231e17d97e86bef139ef430e4f9b94aae0d36c6f1c2f01f0a5531845df80c850",
        "Options": null,
        "Scope": "local"
    }
]

# docker ps -q | xargs -I {} docker inspect --format '{{.Name}} {{range .Mounts}}{{if eq .Name "231e17d97e86bef139ef430e4f9b94aae0d36c6f1c2f01f0a5531845df80c850"}}{{.Name}}{{end}}{{end}}' {}
/kibana 
/elastic 
/sonarqube 231e17d97e86bef139ef430e4f9b94aae0d36c6f1c2f01f0a5531845df80c850
/scouter-server 
/vertica 
/postgres 
/mariadb-develop 
/mariadb-market-product 
/mariadb-market-order 
/mariadb-market-inventory 
/mariadb-market-delivery 
/mariadb-market-customer 
/redis-auth-guest 
/redis-auth-user 
/redis-cache-product 
/cp-kafka-connect 
/cp-kafka 
/cp-zookeeper 
/nexus 
/zipkin 

```

```
#!/bin/bash


docker ps -q | xargs -I {} docker inspect --format '{{.Name}} {{range .Mounts}}{{if eq .Name "3cbeedf67e372e768c4ac38846a2296da6c991b659b45a79220c639d9850b65f"}}{{.Name}}{{end}}{{end}}' {}
```

- IPv6 비활성화

```
##/etc/docker/daemon.json 
#{
#  "insecure-registries": ["localhost:5000"],
#  "dns": ["8.8.8.8", "8.8.4.4"],
#  "hosts": ["tcp://0.0.0.0:2375", "unix:///var/run/docker.sock"],
#  "ip": "0.0.0.0"
#}

#/etc/sysctl.conf
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
```
