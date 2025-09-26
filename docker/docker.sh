#!/usr/bin/env bash
BASEDIR=$(cd $(dirname $0) && pwd -P)
SCRIPT_NM="${0##*/}"

shopt -s globstar

up="\033[A"
clean="\033[K"

# usage
function USAGE {
  cat << EOF
- Usage  $SCRIPT_NM service [OPTIONS] COMMAND [container]
COMMAND:
  start     Start service
  stop      Stop service
  restart   Stop and Start service
  up        Create service
  down      Remove service
  status    'docker ps' command
  logs      Fetch the logs of service

OPTIONS:
  --v       'docker-compose down --v' : down container and remove associate volumes
            'docker-compose stop --v' : stop container and remove associate volumes
  --logs    start command and 'logs -f'

EOF
  exit 1
}
# //usage

# init
declare o_service="$1"; shift
declare yml_list=($(ls **/*.yml 2> /dev/null | awk '{ origin=$0; sub("\\.yml", "", $0); sub("/yml", "", $0); printf "%s|%s\n", origin, $0 }'))
declare entries=($(printf "%s\n" "${yml_list[@]}" | grep "${o_service}$"))

[ -z "${o_service}" ] && {
  echo "[ERROR] require service. (choose one)"
  printf "  %s\n" "${entries[@]#*\|}"
  echo ""
  USAGE
}

declare yml_file
if [ ${#entries[@]} -eq 1 ]; then
  printf "[%-5s] %s" "INFO" "service"
  _tmp=$(printf "%s\n" "${yml_list[@]}" | grep "${o_service}$")
  o_service=${_tmp#*|}
  echo " '${o_service}'"
  yml_file=${_tmp%|*}
elif [ ${#entries[@]} -gt 1 ]; then
  printf "[%-5s] %s" "ERROR" "ambiguous service"
  echo -n "* choose one:"
  for e in ${entries[@]}; do
    echo -n " '${e#*|}'"
  done
  echo ""
  exit
else
  printf "[%-5s] %s\n" "ERROR" "not matched"
  exit
fi

# variable
declare project="${o_service%/*}"
declare service="${o_service#*/}"
declare file="${BASEDIR}/${yml_file}"
declare env_file="${BASEDIR}/${yml_file%/*}/.env"

# options
declare o_rm_vols
declare o_logs
OPTIONS=""
LONGOPTIONS="v,logs"
opts=$(getopt --options "${OPTIONS}" \
              --longoptions "${LONGOPTIONS}" \
              -- "$@" )
eval set -- "${opts}"
while true; do
  [ -z "$1" ] && break
  
  case "$1" in
    --logs)
      o_logs="y"
      ;;
    --v)
      o_rm_vols="y"
      ;;
    --)
      ;;
    *)
      argv+=($1)
      ;;
  esac
  shift
done
# -- options

get_running() {
  local container=$1
  local running=$(docker inspect --format '{{.State.Running}}' ${container} 2>/dev/null)
  echo "${running}"
}

start() {
  docker-compose -p ${project} -f ${file} start
}

stop() {
  docker-compose -p ${project} -f ${file} stop ${o_rm_vols:+--volumes}
}

up() {
  docker-compose -p ${project} -f ${file} up -d
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
}

logs() {
  docker-compose -p ${project} -f ${file} logs -f
}

# main
declare command=${argv[0]}
[ -z "${command}" ] && {
  printf "[%-5s] %s" "ERROR" "require COMMAND"
  USAGE
}

case "${command}" in
  start)
    start && [ "${o_logs}" == "y" ] && logs ;;
  stop)
    stop ;;
  restart)
    stop && start && [ "${o_logs}" == "y" ] && logs ;;
  up)
    up && [ "${o_logs}" == "y" ] && logs ;;
  down)
    down ;;
  recreate)
    down && up ;;
  status)
    status ;;
  logs)
    logs ;;
  volume)
    volume ;;
esac
# -- main
