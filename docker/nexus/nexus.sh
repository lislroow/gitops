#!/usr/bin/env bash
BASEDIR=$(cd $(dirname $0) && pwd -P)
SCRIPT_NM="${0##*/}"

up="\033[A"
clean="\033[K"

# variable
wd=`pwd -P`
group="${wd##*/}"

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
  status    'docker ps' command
  logs      Fetch the logs of containers

Options:
  --v       'docker-compose down --v' : down container and remove associate volumes
            'docker-compose stop --v' : stop container and remove associate volumes
EOF
  exit 1
}
# //usage


# options
declare o_rm_vols
OPTIONS=""
LONGOPTIONS="v"
opts=$(getopt --options "${OPTIONS}" \
              --longoptions "${LONGOPTIONS}" \
              -- "$@" )
eval set -- "${opts}"
while true; do
  [ -z "$1" ] && break
  
  case "$1" in
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
# -- validate



get_running() {
  local service=$1
  local running=$(docker inspect --format '{{.State.Running}}' ${service} 2>/dev/null)
  echo "${running}"
}

start() {
  local project="nexus"
  local file="${BASEDIR}/${project}.yml"
  docker-compose -p ${project} -f ${file} start
}

stop() {
  local project="nexus"
  local file="${BASEDIR}/${project}.yml"
  docker-compose -p ${project} -f ${file} stop ${o_rm_vols:+--volumes}
}

up() {
  local project="nexus"
  local file="${BASEDIR}/${project}.yml"
  docker-compose -f ${file} up -d
}

down() {
  local project="nexus"
  local file="${BASEDIR}/${project}.yml"
  docker-compose -f ${file} down ${o_rm_vols:+--volumes}
}

volume() {
  local project="nexus"
  local file="${BASEDIR}/${project}.yml"
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
}

status() {
  local project="nexus"
  local file="${BASEDIR}/${project}.yml"
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
}

logs() {
  local project="nexus"
  local file="${BASEDIR}/${project}.yml"
  docker-compose -p ${project} -f ${file} logs -f
}

# main
command=${argv[1]}

case "${command}" in
  start)
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
    status
    ;;
  logs)
    logs
    ;;
  volume)
    volume
    ;;
  *)
    USAGE
    ;;
esac
# -- main
