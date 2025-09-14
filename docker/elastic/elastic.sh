#!/usr/bin/env bash
SCRIPT_NM="${0##*/}"

# variable
wd=`pwd -P`
group="${wd##*/}"
project_nm="${group}"

# usage
function USAGE {
  cat << EOF
- Usage  $SCRIPT_NM [OPTIONS] COMMAND [SERVICES]
Commands:
  start     Start containers
  stop      Stop containers
  restart   Stop and Start containers
  up        Create containers
  down      Remove containers
  status    'docker ps' command and curl health check.
  logs      Fetch the logs of containers

Options:
  --ssl     Using 'elastic-ssl.yml' (default elastic.yml)
  --v       Remove anonymous volums attached to containers
            'docker-compose down --v', 'docker-compose stop --v'
EOF
  exit 1
}
# //usage


# options
declare remove_volumes_yn
OPTIONS="a"
LONGOPTIONS="ssl,v,force-recreate"
SetOptions() {
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
      --ssl)
        config_file="${group}-ssl.yml"
        ;;
      --v)
        remove_volumes_yn="y"
        ;;
      *)
        argv+=($1)
        ;;
    esac
    shift
  done

  [ "${#argv[@]}" -eq 0 ] && USAGE
  [ -z "${config_file}" ] && config_file="${group}.yml"
  [ -z "${healthy_yn}" ] && healthy_yn="y"
}
SetOptions "$@"
# -- options


get_status() {
  local service=$1
  local running=$(docker inspect --format '{{.State.Running}}' ${service} 2>/dev/null)
  echo "${running}"
}

start() {
  docker-compose -f ${config_file} start ${service_entry[@]}
  if test "${healthy_yn}" == "y"; then
    local services=($(docker-compose -f ${config_file} config --services))
    healthy 60 ${services[@]}
  fi
}

stop() {
  docker-compose -f ${config_file} stop ${remove_volumes_yn:+-v} ${service_entry[@]}
}

up() {
  docker-compose -f ${config_file} up -d ${service_entry[@]}
  if test "${healthy_yn}" == "y"; then
    local services=($(docker-compose -f ${config_file} config --services))
    healthy 60 ${services[@]}
  fi
}

down() {
  docker-compose -f ${config_file} down ${remove_volumes_yn:+-v}
}

volume() {
  declare volume_list=$(awk '/^volumes:/ {flag=1; next}
    /^[^[:space:]]/ {flag=0}
    flag {
      if ($1 == "") next
      sub(":$", "", $1)
      print $1
    }' "${config_file}")
  for volume in ${volume_list[@]}; do
    vol_nm="${project_nm}_${volume}"
    docker volume inspect ${vol_nm} --format '{{.Mountpoint}}' 2> /dev/null | \
      awk -v vol_nm="${vol_nm}" '{
        mountpoint = $1
        if (mountpoint == "") {
          mountpoint = "X (not exist)"
        }
        printf "%-20s : %s\n", vol_nm, mountpoint
      }'
  done
}

print_status() {
  local list=($@)
  echo "## container status"
  if [ $(docker ps ${status_all_yn:+-a} $(printf ' --filter name=%s' ${list[@]}) | tail -n +2 | wc -l) -eq 0 ]; then
    printf "no containers running\n"
    return 1
  else
    docker ps ${status_all_yn:+-a} $(printf ' --filter name=%s' ${list[@]}) | tail -n +2
  fi

  echo "## project info"
  docker inspect ${list[1]} --format '{{ index .Config.Labels "com.docker.compose.project" }}' \
    | awk '{
      printf "\033[A\033[15C: %s\n", $0
    }'

  echo "## volume info"
  for service in ${list[@]}; do
    docker inspect ${service} --format '{{range .Mounts}}{{.Name}}|{{.Source}}{{"\n"}}{{end}}' \
      | awk -v service="${service}" -F'|' '
      {
        if ($0 == "") next
        idx++
        result[idx] = $1 "|" $2
      }
      END {
        if (idx > 0) {
          printf "%s:\n", service
        }
        for (i=1; i<=idx; i++) {
          split(result[i], arr, "|")
          printf "  - %-20s: %s\n", arr[1], arr[2]
        }
      }
      '
  done
  if [ ${#list[@]} -gt 0 ]; then
    printf "\n"
  fi
}

healthy() {
  echo "## check healthy"
  local max_iter=$1
  shift
  local list=($@)
  
  local up="\033[A"
  local clean="\033[K"
  for item in ${list[@]}; do
    case "$item" in
      elastic)
        ;;
      kibana)
        for ((i=1; i<=${max_iter}; i++)); do
          curl -s -I http://localhost:5601 | grep -q 'HTTP/1.1 302 Found'
          if [ $? -eq 0 ]; then
            echo "${item}: O (healthy)"
            break
          else
            if [ $i -eq ${max_iter} ]; then
              printf "${up}\r${clean}${item}: X (unhealthy)\n"
            elif [ $i -eq 1 ]; then
              printf "${item}: %s%s\n" $(printf '%.0s#' $(seq 1 $i)) $(printf '%.0s.' $(seq $((i+1)) $max_iter))
              sleep 1
            elif [ $i -gt 1 ]; then
              printf "${up}\r${item}: %s%s\n" $(printf '%.0s#' $(seq 1 $i)) $(printf '%.0s.' $(seq $((i+1)) $max_iter))
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
    declare services=($(docker-compose -f ${config_file} config --services))
    declare -i insufficient_cnt=0
    for service in ${services[@]}; do
      if [[ "${#service_entry[@]}" -gt 0 ]] && [[ " ${service_entry[@]} " != *" $service "* ]]; then
        continue
      fi
      running=$(get_status "${service}")
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
    ;;
  stop)
    stop
    ;;
  restart)
    stop
    start
    ;;
  up)
    up
    ;;
  down)
    down
    ;;
  status)
    declare services=($(docker-compose -f ${config_file} config --services))
    print_status ${services[@]}
    [ $? -eq 0 ] && healthy 5 ${services[@]}
    ;;
  logs)
    docker-compose -f ${config_file} logs -f
    ;;
  volume)
    volume
    ;;
  *)
    USAGE
    ;;
esac
# -- main
