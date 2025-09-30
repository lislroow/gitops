#!/usr/bin/env bash
BASEDIR=$(cd $(dirname $0) && pwd -P)
SCRIPT_NM="${0##*/}"

shopt -s globstar

# usage
function USAGE {
  cat << EOF
- Usage  $SCRIPT_NM COMMAND service [OPTIONS]
COMMAND:
  list      'list' available services
  up        'create' and 'start'
  down      'stop' and 'remove'
  recreate  'down' and 'up'
  start     'start'
  stop      'stop'
  restart   'stop' and 'start'
  logs      'logs -f -n 10'
  status    service status

OPTIONS:
  --logs    logs after 'start|restart|up|recreate'
  --v       remove associate volumes 
            'docker-compose [down|stop] --v service'

EOF
  exit 1
}
# //usage

# options
declare p_logs_y
declare p_rm_vols_y
OPTIONS="h"
LONGOPTIONS="help,logs,v"
opts=$(getopt --options "${OPTIONS}" \
              --longoptions "${LONGOPTIONS}" \
              -- "$@" )
eval set -- "${opts}"
while true; do
  [ -z "$1" ] && break
  
  case "$1" in
    -h|--help)
      USAGE
      ;;
    --logs)
      p_logs_y="y"
      ;;
    --v)
      p_rm_vols_y="y"
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
declare p_command=${argv[0]}
if [ -z "${p_command}" ]; then
  printf "[%-5s] %s\n\n" "ERROR" "COMMAND is required"
  USAGE
fi

case "${p_command}" in
  list)
    declare -a list=(**/*.yml)
    printf "* available docker-compose files (${#list[@]})\n"
    declare -i max_len=0; for f in ${list[@]}; do (( ${#f} > max_len )) && max_len=${#f}; done
    for i in $(seq 1 ${#list[@]}); do
      printf "  %2s) %-$((lax_len+2))s\n" "$i" "${list[$((i-1))]}"
    done
    exit
    ;;
esac

declare -a p_targets=("${argv[@]:1}")
if [ ${#p_targets[@]} -eq 0 ]; then
  printf "[%-5s] %s\n\n" "ERROR" "service or project is required"
  USAGE
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

get_yml_services() {
  local file=$1 
  echo $(yq '.services | keys | .[]' $file)
}
# -- functions

# main
declare -a entry_keys=()
declare -A entries
for file in **/*.yml; do
  if [[ "$file" == */* ]]; then
    project=$(awk -F/ '{print $(NF-1)}' <<< ${file})
  else
    project=$(basename `pwd`)
  fi

  declare r_project=${project}
  declare r_file=${file}
  declare r_key="${project}:${file}"

  declare r_services=""
  declare -a services=($(get_yml_services "${file}"))
  if [[ " ${p_targets[@]} " == *" ${project} "* ]]; then  ## 1) 프로젝트명 기준 체크
    r_services=$(IFS=,; echo "${services[*]}")
    entries[${r_key}]="${r_services}"
    # printf "%-9s: %-5s %-15s %s\n" "[project]" "${r_project}" "${r_file}" "${r_services}"
  else
    for p_target in ${p_targets[@]}; do
      if [[ " ${services[@]} " == *" ${p_target} "* ]]; then ## 2) 서비스명 기준 체크
        r_services=${p_target}
        entries[${r_key}]="${r_services}${entries[${r_key}]:+,}${entries[${r_key}]}"
        # printf "%-9s %-5s %-15s %s\n" "[service]" "${r_project}" "${r_file}" "${r_services}"
      fi
    done
    if [[ " ${p_targets[@]} " == *" ${file} "* ]]; then ## 3) 파일명 기준 체크
      r_services=$(IFS=,; echo "${services[*]}")
      entries[${r_key}]="${r_services}"
      # printf "%-9s %-5s %-15s %s\n" "[file]" "${r_project}" "${r_file}" "${r_services}"
    fi
  fi
  
  # 체크 결과 저장
  # printf "%-9s %-5s %-15s %s\n" "[check!!]" "${r_project}" "${r_file}" "${r_services}"
  if [ -n "${r_services}" ]; then
    declare merged=$(echo "${entries[${r_key}]}" | tr ',' '\n' | sort -u | paste -sd,)
    entries[${r_key}]=${merged}
    entry_keys+=(${r_key})
  fi
done

for s in "${entry_keys[@]}"; do (( ${#s} > max )) && max=${#s}; done
for key in ${entry_keys[@]}; do
  printf "%-$((max))s : %s\n" "${key}" "${entries[$key]}"
done
exit

# declare -a m_services=()
declare -a m_entries=()
for file in **/*.yml; do
  declare -a services_in_file=($(yq '.services | keys | .[]' $file))
  ## match project
  if [[ " ${p_targets[@]} " == *" $(awk -F/ '{print $(NF-1)}' <<< ${file}) "* ]]; then
    m_entries=("${file}:${services_in_file[*]}")
    continue
  fi

  ## match service
  for svc in ${services_in_file[@]}; do
    if [[ " ${p_targets[@]} " == *" ${svc} "* ]]; then
      for entry in ${m_entries[@]}; do
        _file=${entry%:*}
        _services_in_file=(IFS=, read -ra arr <<< "${entry#*:}"; echo "${arr[*]}")
        if (( $(printf "%s\n" ${_services_in_file[@]} | grep -o ${svc} | wc -l) > 0 )); then
          m_entries="${file}:${svc}"
        fi
      done
    fi


    declare -a m_entries_svc=()
    if [[ " ${p_targets[@]} " == *" ${svc} "* ]]; then
      if [ $(printf "%s\n" ${m_entries_svc[@]} | grep -oE "^${svc}$" | wc -l) -eq 0 ]; then
        m_entries_svc+=(${svc})
        m_entries[$file]=${m_entries_svc[*]}
      fi
    fi
  done
  ## match compose file
  if [[ " ${p_targets[@]} " == *" ${file} "* ]]; then
    declare -a services_in_file=($(yq '.services | keys | .[]' $file))
    m_entries[$file]=${services_in_file[*]}
  fi
done

for file in ${!m_entries[@]}; do
  echo "compose: ${file}, svc-list: ${m_entries[$file]}"
done

exit

if [ ${#m_entries[@]} -eq 0 ]; then
  printf "[%-5s] %s\n" "ERROR" "available files"
  printf "  %s\n" "${m_all_entries[@]}"
  echo ""
  exit
fi

## process each service individually
declare -i tot=${#m_entries[@]}
declare -i idx
for key in ${m_entries[@]}; do
  declare project
  declare compose_file
  declare service
  declare env_file
  if [ $(echo "${key}" | grep -o '/' | wc -l) -eq 0 ]; then
    project="$(basename `pwd`)"
    compose_file="${key}"
    service="${compose_file%.*}"
    env_file=".env"
  else
    project=$(awk -F/ '{print $(NF-1)}' <<<"$key")
    compose_file="${key}"
    service=$(awk -F/ '{sub(".yml", "", $NF); print $(NF)}' <<<"$key")
    env_file="${project}/.env"
  fi

  m_services+=("${service}")
  declare -a compose_files=($(get_depends_file "${project}" "${compose_file}"))

  ((idx++))
  cat <<-EOF
* [${idx}/${tot}] ${key}
  project    : ${project}
  service    : ${service}
  env        : ${env_file}
  compose    : ${compose_file}
  depends on : ${compose_files[@]:-(none)}
EOF
  
  [ $(echo "${compose_files[@]}" | grep -o "${compose_file}" | wc -l) -eq 0 ] && \
    compose_files+=(${compose_file})
  case "${p_command}" in
    start|stop|up|down)
      exec_compose "${p_command}" "${project}" "${service}" "${compose_files[*]}"
      ;;
    restart)
      exec_compose "stop" "${project}" "${service}" "${compose_files[*]}"
      exec_compose "start" "${project}" "${service}" "${compose_files[*]}"
      ;;
    recreate)
      exec_compose "down" "${project}" "${service}" "${compose_files[*]}"
      exec_compose "up" "${project}" "${service}" "${compose_files[*]}"
      ;;
  esac
done

## process all services together
case "${p_command}" in
  logs)
    sleep 0.3
    exec_compose "logs" "${project}" "${m_services[*]}" # caution: (O) m_services[*], (X) m_services[@]
    ;;
  start|restart|up|recreate)
    if [ "${p_logs_y}" == "y" ]; then
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
