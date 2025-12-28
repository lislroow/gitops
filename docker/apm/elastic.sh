#!/usr/bin/env bash
BASEDIR=$(cd $(dirname $0) && pwd -P)
SCRIPT_NM="${0##*/}"

up="\033[A"
clean="\033[K"

# variable
declare project="apm"
declare service="elastic"
declare file="${BASEDIR}/yml/${service}.yml"
declare env_file="${BASEDIR}/yml/.env"

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
  --v       'docker-compose down --volumes' : down container and remove associate volumes
            'docker-compose stop --volumes' : stop container and remove associate volumes
  --logs    start command and 'logs -f'
EOF
  exit 1
}
# //usage


# options
declare o_ssl
declare o_rm_vols
declare o_logs
OPTIONS="a"
# LONGOPTIONS="ssl,v,logs"
LONGOPTIONS="v,logs"
opts=$(getopt --options "${OPTIONS}" \
              --longoptions "${LONGOPTIONS}" \
              -- "$@" )
eval set -- "${opts}"
while true; do
  [ -z "$1" ] && break
  
  case "$1" in
    -a)
      status_all_yn="y"
      ;;
    # --ssl)
    #   o_ssl="y"
    #   ;;
    --logs)
      o_logs="y"
      ;;
    --v)
      o_rm_vols="y"
      ;;
    *)
      argv+=($1)
      ;;
  esac
  shift
done
# -- options

# validate
[ "${#argv[@]}" -eq 0 ] && USAGE
[ -z "${healthy_yn}" ] && healthy_yn="y"
# -- validate

# infer_project() {
#   for project in elastic elastic-ssl; do
#     if [ $(docker-compose -p ${project} ps -a | tail -n +2 | wc -l) -gt 0 ]; then
#       echo ${project}
#       break
#     fi
#   done
# }

get_running() {
  local container=$1
  local running=$(docker inspect --format '{{.State.Running}}' ${container} 2>/dev/null)
  echo "${running}"
}

start() {
  docker-compose -p ${project} -f ${file} start ${service_entry[@]}
  if test "${healthy_yn}" == "y"; then
    local services=($(docker-compose -p ${project} -f ${file} config --services))
    healthy 60 ${services[@]}
  fi
}

stop() {
  docker-compose -p ${project} -f ${file} stop ${o_rm_vols:+--volumes} ${service_entry[@]}
}

up() {
  docker-compose -p ${project} -f ${file} up -d ${service_entry[@]}
  if test "${healthy_yn}" == "y"; then
    local services=($(docker-compose -p ${project} -f ${file} config --services))
    healthy 60 ${services[@]}
  fi
  prune_container
}

prune_container() {
  local service="elastic${o_ssl:+-ssl}"
  local file="elastic${o_ssl:+-ssl}.yml"
  if [ "${o_ssl}" == "y" ]; then
    docker rm -f elastic-certs
  fi
  docker rm -f elastic-users
}

down() {
  docker-compose -p ${project} -f ${file} down ${o_rm_vols:+--volumes}
}

volume() {
  local volume_list=($(awk '/^volumes:/ {flag=1; next}
    /^[^[:space:]]/ {flag=0}
    flag {
      if ($1 == "") next
      sub(":$", "", $1)
      print $1
    }' "${file}"))
  declare -i max_len=0
  for item in ${volume_list[@]}; do
    local volume="${project}_${item}"
    [ ${max_len} -lt ${#volume} ] && max_len=${#volume}
  done
  for item in ${volume_list[@]}; do
    local volume="${project}_${item}"
    docker volume inspect ${volume} --format '{{.Mountpoint}}' 2> /dev/null | \
      awk -v volume="${volume}" -v max_len="${max_len}" '{
        if ($1 == "") {
          $1 = "X (not exist)"
        }
        fmt = "   %-" max_len "s   %s\n"
        printf fmt, volume, $1
      }'
  done

  # 개선 필요
  ls -ld /data/apm/kibana-data
  ls -ld /data/apm/elastic-data
}

status() {
  local list=($(docker-compose -p ${project} -f ${file} ps -a | tail -n +2 | awk '{ print $1 }'))
  echo "## containers"
  echo " * project: ${project}"
  declare -i max_len=0
  declare -a running=()
  for service in ${list[@]}; do
    [ $max_len -lt ${#service} ] && max_len=${#service}
  done
  
  for service in ${list[@]}; do
    local status=$(docker inspect ${service} --format '{{.State.Status}}' 2> /dev/null)
    case "${status}" in
      running)
        printf "   %-${max_len}s   %s\n" "${service}" "${status}"
        running+=(${service})
        ;;
      exited)
        printf "   %-${max_len}s   %s\n" "${service}" "${status}"
        ;;
      *)
        printf "   %-${max_len}s   unknown status '%s'\n" "${service}" "${status}"
        ;;
    esac
  done
  
  echo ""
  echo "## volumes"
  volume
  if [ ${#list[@]} -gt 0 ]; then
    printf "\n"
  fi
  [ ${#running[@]} -gt 0 ] && healthy 5 ${running[@]}
}

logs() {
  docker-compose -p ${project} -f ${file} logs -f
}

healthy() {
  echo "## check healthy"
  local max_iter=$1
  shift
  local list=($@)
  declare -i max_len=0
  for item in ${list[@]}; do
    [ ${max_len} -lt ${#item} ] && max_len=${#item}
  done
  
  for item in ${list[@]}; do
    case "$item" in
      elastic)
        for ((i=1; i<=${max_iter}; i++)); do
          test -f "${env_file}" && \
            export $(grep -v '^#' "${env_file}" | xargs)
          if [ "${o_ssl:+y}" == "y" ]; then
            crt_file="/var/lib/docker/volumes/${project}_elastic_certs/_data/ca/ca.crt"
            curl -s -u "elastic:${elastic_password}" --cacert $crt_file https://localhost:9200/_cluster/health | grep -q "\"status\":\"green\"\\|\"status\":\"yellow\""
          else
            curl -s -u "elastic:${elastic_password}" http://localhost:9200/_cluster/health | grep -q "\"status\":\"green\"\\|\"status\":\"yellow\""
          fi
          
          if [ $? -eq 0 ]; then
            printf "   %-${max_len}s   O (healthy)\n" "${item}"
            break
          else
            if [ $i -eq ${max_iter} ]; then
              printf "${up}\r${clean}   ${item}: X (unhealthy)\n" "${item}"
            elif [ $i -eq 1 ]; then
              printf "   %-${max_len}s   %s%s\n" "${item}" $(printf '%.0s#' $(seq 1 $i)) $(printf '%.0s.' $(seq $((i+1)) $max_iter))
              sleep 1
            elif [ $i -gt 1 ]; then
              printf "${up}\r   %-${max_len}s   %s%s\n" "${item}" $(printf '%.0s#' $(seq 1 $i)) $(printf '%.0s.' $(seq $((i+1)) $max_iter))
              sleep 1
            fi
          fi
        done
        ;;
      kibana)
        for ((i=1; i<=${max_iter}; i++)); do
          curl -s -I http://localhost:5601 | grep -q 'HTTP/1.1 302 Found'
          if [ $? -eq 0 ]; then
            printf "   %-${max_len}s   O (healthy)\n" "${item}"
            break
          else
            if [ $i -eq ${max_iter} ]; then
              printf "${up}\r${clean}   %-${max_len}s   (unhealthy)\n" "${item}"
            elif [ $i -eq 1 ]; then
              printf "   %-${max_len}s   %s%s\n" "${item}" $(printf '%.0s#' $(seq 1 $i)) $(printf '%.0s.' $(seq $((i+1)) $max_iter))
              sleep 1
            elif [ $i -gt 1 ]; then
              printf "${up}\r   %-${max_len}s   %s%s\n" "${item}" $(printf '%.0s#' $(seq 1 $i)) $(printf '%.0s.' $(seq $((i+1)) $max_iter))
              sleep 1
            fi
          fi
        done
        ;;
      *)
        ;;
    esac
  done
}

# main
command=${argv[1]}
service_entry=("${argv[@]:2}")

case "${command}" in
  start)
    services=($(docker-compose -p ${project} -f ${file} config --services))
    declare -i insufficient_cnt=0
    for service in ${services[@]}; do
      if [[ "${#service_entry[@]}" -gt 0 ]] && [[ " ${service_entry[@]} " != *" $service "* ]]; then
        continue
      fi
      running=$(get_running "${service}")
      case "${running}" in
        true|false)
          ;;
        *)
          printf "%-20s: not created\n" "${service}"
          insufficient_cnt=$((insufficient_cnt+1))
          ;;
      esac
    done
    [ ${insufficient_cnt} -gt 0 ] && exit 1

    start
    [ "${o_logs}" == "y" ] && logs
    ;;
  stop)
    stop
    ;;
  restart)
    stop
    start
    [ "${o_logs}" == "y" ] && logs
    ;;
  up)
    up
    [ "${o_logs}" == "y" ] && logs
    ;;
  down)
    down
    ;;
  status)
    status
    ;;
  logs)
    logs
    ;;
  volume)
    volume
    ;;
  project)
    get_project_name
    ;;
  *)
    USAGE
    ;;
esac
# -- main
