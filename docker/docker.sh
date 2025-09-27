#!/usr/bin/env bash
BASEDIR=$(cd $(dirname $0) && pwd -P)
SCRIPT_NM="${0##*/}"

shopt -s globstar

# usage
function USAGE {
  cat << EOF
- Usage  $SCRIPT_NM COMMAND service [OPTIONS]
COMMAND:
  up        'create' and 'start'
  down      'stop' and 'remove'
  recreate  'down' and 'up'
  start     'start'
  stop      'stop'
  restart   'stop' and 'start'
  logs      'logs -f -n 10'
  status    service status

OPTIONS:
  --show    show available service list
  --logs    logs after 'start|restart|up|recreate'
  --v       remove associate volumes 
            'docker-compose [down|stop] --v service'

EOF
  exit 1
}
# //usage

# options
declare show_y
declare logs_y
declare project_y
declare rm_vols_y
OPTIONS=""
LONGOPTIONS="show,logs,project,v"
opts=$(getopt --options "${OPTIONS}" \
              --longoptions "${LONGOPTIONS}" \
              -- "$@" )
eval set -- "${opts}"
while true; do
  [ -z "$1" ] && break
  
  case "$1" in
    --show)
      show_y="y"
      ;;
    --logs)
      logs_y="y"
      ;;
    --project)
      project_y="y"
      ;;
    --v)
      rm_vols_y="y"
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
declare -a m_all_entries=($(ls **/*.yml 2> /dev/null | awk '{ origin=$0; sub("\\.yml", "", $0); sub("", "", $0); printf "%s,%s\n", origin, $0 }'))
# echo "m_all_entries=(${m_all_entries[@]})"
if [ "${show_y}" == "y" ]; then
  printf "* available service list\n"
  printf "  %s\n" "${m_all_entries[@]#*\,}"
  exit
fi

declare p_command=${argv[0]}
if [ -z "${p_command}" ]; then
  printf "[%-5s] %s\n\n" "ERROR" "COMMAND is required"
  USAGE
fi

# declare -a p_targets=("${argv[@]:0:${#argv[@]}-1}")
declare -a p_targets=("${argv[@]:1}")
# echo "p_targets=(${p_targets[@]})"
if [ ${#p_targets[@]} -eq 0 ]; then
  printf "[%-5s] %s\n\n" "ERROR" "service or project required"
  USAGE
fi

declare -a m_entries
if [ "${project_y}" == "y" ]; then
  m_entries=($(printf "%s\n" "${m_all_entries[@]}" | grep "^${p_targets}/"))
else
  _grep_str=$(IFS='|'; echo "(${p_targets[*]})") # caution
  m_entries=($(printf "%s\n" "${m_all_entries[@]}" | grep -E "${_grep_str}$"))
fi
if [ ${#m_entries[@]} -eq 0 ]; then
  printf "[%-5s] %s\n" "ERROR" " use '--project' or choose one"
  for e in ${m_all_entries[@]}; do
    echo -n " '${e#*,}'"
  done
  echo ""
  exit
fi
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
  [ ! -e "${BASEDIR}/${project_nm}" ] && { echo "'${BASEDIR}/${project_nm}' does not exist." 1>&2; return; }
  [ ! -d "${BASEDIR}/${project_nm}" ] && { echo "'${BASEDIR}/${project_nm}' is not directory." 1>&2; return; }
  [ -z "${service_nm}" ] && { echo "'${service_nm}' is required" 1>&2; return; }

  for yml_file in ${BASEDIR}/${project_nm}/*.yml; do
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

exec_compose() {
  local command="$1"
  local project="$2"
  local service="$3"
  local compose_files=("$4")
  case "${command}" in
    start|stop|down)
      ;;
    up)
      command+=" -d"
      ;;
    logs)
      command+=" -f -n 10"
      ;;
    *)
      printf "[%-5s] %s\n\n" "ERROR" "invalid docker-compose command. (avaiable: start, stop, up, down, logs)" 1>&2
      return
      ;;
  esac
  [ -z "${service}" ] && [[ "${command}" != "logs"* ]] && { printf "[%-5s] %s\n\n" "ERROR" "service is required." 1>&2; return; }
  [ ${#compose_files[@]} -eq 0 ] && [[ "${command}" != "logs"* ]] && { printf "[%-5s] %s\n\n" "ERROR" "compose files are required"; return; }

  local compose_opts
  for item in ${compose_files[@]}; do
    compose_opts="${compose_opts} -f ${item}"
  done
  
  echo "docker-compose -p ${project} ${compose_opts:1} ${command} ${service}"
  docker-compose -p ${project} ${compose_opts:1} ${command} ${service}
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
  local running=$(docker inspect --format '{{.State.Running}}' ${container} 2>/dev/null)

  echo ""
  echo "## volumes"
  volume
  if [ ${#list[@]} -gt 0 ]; then
    printf "\n"
  fi
}
# -- functions

# variables
declare -a m_services=()
# -- variables

# main
## process each service individually
declare -i tot=${#m_entries[@]}
declare -i idx
for entry in ${m_entries[@]}; do
  declare target="${entry#*,}"
  declare project="${target%/*}"
  declare service="${target#*/}"
  m_services+=("${service}")
  declare env_file="${BASEDIR}/${project}/.env"
  declare compose_file="${BASEDIR}/${entry%,*}"

  declare -a compose_files=($(get_depends_file "${project}" "${compose_file}"))
  if [[ "${compose_files[@]}" != *" ${compose_file} "* ]]; then
    compose_files+=(${compose_file})
  fi

  ((idx++))
  cat <<-EOF
* [${idx}/${tot}] target '${target}'
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
  case "${p_command}" in
    start|stop|up|down)
      exec_compose "${p_command}" "${project}" "${service}" "${compose_files}"
      ;;
    restart)
      exec_compose "stop" "${project}" "${service}" "${compose_files}"
      exec_compose "start" "${project}" "${service}" "${compose_files}"
      ;;
    recreate)
      exec_compose "down" "${project}" "${service}" "${compose_files}"
      exec_compose "up" "${project}" "${service}" "${compose_files}"
      ;;
  esac
done

## process all services together
case "${p_command}" in
  logs)
    sleep 0.3
    exec_compose "logs" "${project}" "${m_services[*]}"
    ;;
  start|restart|up|recreate)
    if [ "${logs_y}" == "y" ]; then
      sleep 0.5
      exec_compose "logs" "${project}" "${m_services[*]}"
    fi
    ;;
  status)
    sleep 0.3
    # exec_compose "status" "${m_services[*]}"
    ;;
  volume)
    sleep 0.3
    # exec_compose "volume" "${m_services[*]}"
    ;;
esac
# -- main
