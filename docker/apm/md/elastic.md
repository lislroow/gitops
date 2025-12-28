#### .env

```
ELASTIC_PASSWORD=
KIBANA_PASSWORD=
```


#### elastic.sh

```shell
# usage
function USAGE {
  cat << EOF
- Usage  $SCRIPT_NM [OPTIONS] COMMAND [container]
COMMAND:
  start     Start containers
  stop      Stop containers
  restart   Stop and Start containers
  up        Create containers
  down      Remove containers
  status    'docker ps' command and curl health check.
  logs      Fetch the logs of containers

OPTIONS:
  --ssl     'docker-compose up --ssl' : Using 'elastic-ssl.yml' 
            'docker-compose up'       : Using 'elastic.yml'
  --v       'docker-compose down --v' : down container and remove associate volumes
            'docker-compose stop --v' : stop container and remove associate volumes
EOF
  exit 1
}
# //usage
```


#### elastic.yml


#### elastic-ssl.yml

