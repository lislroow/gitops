#!/usr/bin/env bash
BASEDIR=$(cd $(dirname $0) && pwd -P)
SCRIPT_NM="${0##*/}"

shopt -s globstar

up="\033[A"
clean="\033[K"

# usage
function USAGE {
  cat << EOF
- Usage  $SCRIPT_NM COMMAND service [OPTIONS]
COMMAND:
  start     Start service
  stop      Stop service
  restart   Stop and Start service
  up        Create service
  down      Remove service
  recreate  Remove and Create service
  status    'docker ps' command
  logs      Fetch the logs of service

OPTIONS:
  --list    print available service list
  --logs    Start command and 'logs -f'
  --v       'docker-compose down --v' : down container and remove associate volumes
            'docker-compose stop --v' : stop container and remove associate volumes

EOF
  exit 1
}
# //usage

# options
declare o_list
declare o_logs
declare o_project
declare o_rm_vols
OPTIONS=""
LONGOPTIONS="list,logs,project,v"
opts=$(getopt --options "${OPTIONS}" \
              --longoptions "${LONGOPTIONS}" \
              -- "$@" )
eval set -- "${opts}"
while true; do
  [ -z "$1" ] && break
  
  case "$1" in
    --list)
      o_list="y"
      ;;
    --logs)
      o_logs="y"
      ;;
    --project)
      o_project="y"
      ;;
    --v)
      o_rm_vols="y"
      ;;
    --)
      ;;
    --*)
      printf "[%-5s] %s\n" "ERROR" "invalid option: '$1'"
      exit
      ;;
    *)
      argv+=($1)
      ;;
  esac
  shift
done
# -- options

# init
declare o_target=${argv[0]}
# echo "o_target: ${o_target}"
declare all_entries=($(ls **/*.yml 2> /dev/null | awk '{ origin=$0; sub("\\.yml", "", $0); sub("/yml", "", $0); printf "%s,%s\n", origin, $0 }'))
# echo "all_entries: ${all_entries[@]}"
declare entries
if [ -n "${o_project}" ]; then
  entries=($(printf "%s\n" "${all_entries[@]}" | grep "^${o_target}/"))
else
  entries=($(printf "%s\n" "${all_entries[@]}" | grep "${o_target}$"))
fi
if [ "${o_list}" == "y" ]; then
  printf "* available service list\n"
  printf "  %s\n" "${entries[@]#*\,}"
  exit
fi

declare command=${argv[1]}
if [ -z "${command}" ]; then
  printf "[%-5s] %s\n\n" "ERROR" "COMMAND is required"
  USAGE
fi
if [ -z "${o_target}" ]; then
  printf "[%-5s] %s\n\n" "ERROR" "service or project required"
  USAGE
fi
if [ ${#entries[@]} -eq 0 ]; then
  printf "[%-5s] %s\n" "ERROR" " use '--project' or choose one"
  for e in ${all_entries[@]}; do
    echo -n " '${e#*,}'"
  done
  echo ""
  exit
elif [ ${#entries[@]} -ge 2 ] && [ -z "${o_project}" ]; then
  printf "[%-5s] %s\n" "ERROR" "ambiguous service. use '--project' or choose one"
  for e in ${all_entries[@]}; do
    echo -n " '${e#*,}'"
  done
  echo ""
  exit
fi
# echo "command: ${command}, o_target: ${o_target}"
# -- init

# functions
get_depends() {
  local yml_file="$1"
  [ ! -f "${yml_file}" ] && { echo "'${yml_file}' does not exsit" 1>&2; return; }

  local depends=($(yq '.services[].depends_on | select(. != null) | keys | .[]' $yml_file))
  echo "${depends[@]}"
}

get_compose() {
  local project_nm="$1"
  local service_nm="$2"
  [ -z "${project_nm}" ] && { echo "'${project_nm}' is required" 1>&2; return; }
  [ ! -e "${BASEDIR}/${project_nm}/yml" ] && { echo "'${BASEDIR}/${project_nm}/yml' does not exist." 1>&2; return; }
  [ ! -d "${BASEDIR}/${project_nm}/yml" ] && { echo "'${BASEDIR}/${project_nm}/yml' is not directory." 1>&2; return; }
  [ -z "${service_nm}" ] && { echo "'${service_nm}' is required" 1>&2; return; }

  for yml_file in ${BASEDIR}/${project_nm}/yml/*.yml; do
    local cnt=$(yq '.services | keys | .[]' $yml_file | grep -E '^('$service_nm')$' | wc -l)
    # echo "cnt: ${cnt}, yml_file: ${yml_file}" 1>&2
    if [ $cnt -gt 0 ]; then
      echo "${yml_file}"
      break
    fi
  done
}

get_depends_file() {
  local project_nm="$1"
  local yml_file="$2"
  [ ! -f "${yml_file}" ] && { echo "'${yml_file}' does not exsit" 1>&2; return; }
  local depends_service_list=($(get_depends "${yml_file}"))
  [ ${#depends_service_list[@]} -eq 0 ] && return
  
  # echo "## ${depends_service_list[@]}" 1>&2

  local compose_file
  for item in ${depends_service_list[@]}; do
    compose_file+=($(get_compose "${project_nm}" "${item}"))
  done
  echo "${compose_file[@]}"
}

get_running() {
  local container=$1
  local running=$(docker inspect --format '{{.State.Running}}' ${container} 2>/dev/null)
  echo "${running}"
}

exec_compose() {
  local cmd="$1"
  case "${cmd}" in
    start|stop|down)
      ;;
    up)
      cmd+=" -d"
      ;;
    logs)
      cmd+=" -f"
      ;;
    *)
      printf "[%-5s] %s\n\n" "ERROR" "invalid docker-compose command. (avaiable: start, stop, up, down, logs)"
      return
      ;;
  esac
  local service="$2"
  local compose_files=("$3")
  [ -z "${service}" ] && { printf "[%-5s] %s\n\n" "ERROR" "service is required"; return; }
  [ ${#compose_files[@]} -eq 0 ] && { printf "[%-5s] %s\n\n" "ERROR" "compose files are required"; return; }
  local compose_opts
  for item in ${compose_files[@]}; do
    compose_opts="${compose_opts} -f ${item}"
  done
  docker-compose -p ${project} ${compose_opts:1} ${cmd} ${service}
}

volume() {
  local volume_list=($(awk '/^volumes:/ {flag=1; next}
    /^[^[:space:]]/ {flag=0}
    flag {
      if ($1 == "") next
      sub(":$", "", $1)
      print $1
    }' "${compose_file}"))
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
  local list=($(docker-compose ${project_opt} ${file_opt} ps -a | tail -n +2 | awk '{ print $1 }'))
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
# -- functions

# variables
declare project
declare -a compose_files
declare env_file
# -- variables


# main
for entry in "${entries[@]}"; do
  declare target="${entry#*,}"
  project="${target%/*}"
  declare service="${target#*/}"
  env_file="${BASEDIR}/${project}/.env"
  declare compose_file="${BASEDIR}/${entry%,*}"

  compose_files=($(get_depends_file "${project}" "${compose_file}"))
  if [[ "${compose_files[@]}" != *" ${compose_file} "* ]]; then
    compose_files+=(${compose_file})
  fi

  cat <<-EOF
* target '${target}'
  project   : ${project}
  service   : ${service}
  env       : ${env_file}
  compose   : ${compose_file}
EOF
  printf "%s" "  list in project : "
  if [ ${#compose_files[@]} -gt 0 ]; then
    printf " > \n"
    printf "    %s\n" "${compose_files[@]}"
    printf "\n"
  else
    printf "(none)\n"
    printf "\n"
  fi
  
  compose_files="${compose_files[@]}" # joined
  case "${command}" in
    start)
      exec_compose "start" "${service}" "${compose_files}"
      [ "${o_logs}" == "y" ] && logs
      ;;
    stop)
      exec_compose "stop" "${service}" "${compose_files}"
      ;;
    restart)
      exec_compose "stop" "${service}" "${compose_files}"
      exec_compose "start" "${service}" "${compose_files}"
      [ "${o_logs}" == "y" ] && logs
      ;;
    up)
      exec_compose "up" "${service}" "${compose_files}"
      [ "${o_logs}" == "y" ] && logs
      ;;
    down)
      exec_compose "down" "${service}" "${compose_files}"
      ;;
    recreate)
      exec_compose "down" "${service}" "${compose_files}"
      exec_compose "up" "${service}" "${compose_files}"
      [ "${o_logs}" == "y" ] && logs
      ;;
    status)
      status ;;
    logs)
      exec_compose "logs" "${service}" "${compose_files}"
      ;;
    volume)
      volume ;;
  esac
done
# -- main
