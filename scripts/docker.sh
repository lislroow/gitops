#!/usr/bin/env bash
BASEDIR=$(cd $(dirname $0) && pwd -P)
SCRIPT_NM="${0##*/}"

shopt -s globstar nullglob

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

OPTIONS:
  --logs    logs after 'start|restart|up|recreate'

EOF
  exit 1
}

function LIST {
  local -a compose_files=(**/*.yml)
  local -i file_cnt=${#compose_files[@]}
  # printf "* available list (${file_cnt})\n"
  
  local -i f3_len=$(printf "%s\n" ${compose_files[@]} | wc -L)
  local FORMAT="  %2s  %-7s  %-$((f3_len+2))s  %s\n"
  local output=$(printf "${FORMAT}" "NO" "PROJECT" "FILE" "SERVICES")
  output+="\n"
  for ((i=0; i<file_cnt-1; i++)); do
    local file=${compose_files[$i]}
    if (( $(echo "${file}" | grep -o '/' | wc -l) == 0 )); then
      project="$(basename $PWD)"
    else
      project="$(awk -F/ '{print $(NF-1)}' <<< ${file})"
    fi
    local -a services=($(yq '.services | keys | .[]' $file))
    service_list="$(IFS=,; echo "${services[*]}")"
    output+=$(printf "${FORMAT}" "$((i+1))" "${project}" "${file}" "${service_list}")
    output+="\n"
  done
  echo -e "${output}"
  exit
}
# //usage

# options
declare p_logs_y
declare OPTIONS="h"
declare LONGOPTIONS="help,logs"
declare opts=$(getopt --options "${OPTIONS}" \
                      --longoptions "${LONGOPTIONS}" \
                      -- "$@" )
eval set -- "${opts}"
while true; do
  [[ -z $1 ]] && break
  
  case "$1" in
    -h|--help)
      USAGE
      ;;
    --logs)
      p_logs_y="y"
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
declare -a p_targets=("${argv[@]:1}")
init() {
  if [[ -z ${p_command} ]]; then
    printf "[%-5s] %s\n\n" "ERROR" "COMMAND is required"
    printf " : %s\n" "'${SCRIPT_NM} -h'"
    exit
  fi


  case "${p_command}" in
    list)
      LIST
      exit
      ;;
    up|down|recreate|start|stop|restart|logs)
      ;;
    *)
      printf "[%-5s] %s\n" "ERROR" "invalid COMMAND. '${p_command}'"
      printf " : %s\n" "'${SCRIPT_NM} -h'"
      exit
      ;;
  esac

  if (( ${#p_targets[@]} == 0 )); then
    printf "[%-5s] %s\n" "ERROR" "service or project is required. check available list."
    printf " : %s\n" "'${SCRIPT_NM} -h' or '${SCRIPT_NM} list'"
    exit
  fi
}
init

declare -A g_all_entries
declare -a g_all_entry_keys=()

fn_all_entries() {
  local -a all_compose_files=(**/*.yml)
  if (( ${#all_compose_files[@]} > 0 )); then
    local r_project=""
    local r_file=""
    local r_key=""
    local r_services=""
    for file in ${all_compose_files[@]}; do
      if [[ "${file}" == */* ]]; then
        r_project=$(awk -F/ '{print $(NF-1)}' <<< "${file}")
      else
        r_project=$(basename `pwd`)
      fi
      r_file="${file}"
      r_key="${r_project}:${r_file}"
      local -a services=($(yq '.services | keys | .[]' "${file}"))
      r_services=$(IFS=,; echo "${services[*]}")
      g_all_entries[${r_key}]="${r_services}"
      g_all_entry_keys+=(${r_key})
    done
  fi
}
fn_all_entries
# -- init



# functions
exec_compose() {
  local command="$1"
  local project="$2"
  local -a services=($(IFS=,; read -ra services <<< "$3"; echo "${services[@]}"))
  local compose_files=("$4")

  local detach_opt_y
  case "${command}" in
    start|stop|down)
      ;;
    up)
      detach_opt_y="y"
      ;;
    logs)
      command+=" -f -n 10"
      ;;
    *)
      printf "[%-5s] %s\n\n" "ERROR" "invalid docker-compose command. (avaiable: start, stop, up, down, logs)" 1>&2
      return
      ;;
  esac
  if [[ ${command} != "logs"* ]]; then
    (( ${#services[@]} == 0 )) && { printf "[%-5s] %s\n\n" "ERROR" "services are required." 1>&2; return; }
    (( ${#compose_files[@]} == 0 )) && { printf "[%-5s] %s\n\n" "ERROR" "compose files are required"; return; }
  fi

  local compose_opts
  for item in ${compose_files[@]}; do
    compose_opts="${compose_opts} -f ${item}"
  done
  
  echo "docker-compose -p ${project} ${compose_opts:1} ${command} ${detach_opt_y:+-d} ${services[@]}"
  docker-compose -p ${project} ${compose_opts:1} ${command} ${detach_opt_y:+-d} ${services[@]}
}
# -- functions



# main process
declare -A g_entries
declare -a g_entry_keys=()

fn_entries() {
  for target in ${p_targets[@]}; do
    local r_project=""
    local r_file=""
    local r_key=""
    local r_services=""
    
    local logs_txt=""
    local logs_services=""

    local project="${target}"
    local -a compose_files=(**/${project}/*.yml)
    if (( ${#compose_files[@]} > 0 )); then
      logs_txt=$(printf "[INFO] filter by %-12s: > " "project-name")
      for file in ${compose_files[@]}; do
        r_project="${project}"
        r_file="${file}"
        r_key="${r_project}:${r_file}"
        local -a services=($(yq '.services | keys | .[]' "${file}"))
        r_services=$(IFS=,; echo "${services[*]}")
        g_entries[${r_key}]="${r_services}"

        local merged=$(echo "${g_entries[${r_key}]}" | tr ',' '\n' | sort -u | paste -sd,)
        g_entries[${r_key}]=${merged}
        g_entry_keys+=(${r_key})
        
        logs_services+="${logs_services:+,}${r_services}"
      done
      [[ -n ${logs_services} ]] && { echo "${logs_txt}${logs_services}"; continue; }
    else
      local service="${target}"
      logs_txt=$(printf "[INFO] filter by %-12s: > " "service-name")
      for key in ${g_all_entry_keys[@]}; do
        r_key="${key}"
        local -a arr=($(IFS=,; read -ra arr <<< ${g_all_entries[$r_key]}; echo "${arr[@]}"))
        if (( $(printf "%s\n" ${arr[@]} | grep -o ^"${service}"$ | wc -l) > 0 )); then
          r_services="${service}"
          g_entries[${r_key}]="${r_services}${g_entries[${r_key}]:+,}${g_entries[${r_key}]}"
          local merged=$(echo "${g_entries[${r_key}]}" | tr ',' '\n' | sort -u | paste -sd,)
          r_services="${merged}"
          g_entries[${r_key}]=${r_services}
          g_entry_keys+=(${r_key})
          logs_services="${r_services}"
          break
        fi
      done
      [[ -n ${logs_services} ]] && { echo "${logs_txt}${logs_services}"; continue; }

      local file="${target}"
      logs_txt=$(printf "[INFO] filter by %-12s: > " "file-name")
      if (( $(printf "%s\n" ${!g_all_entries[@]} | grep -o ":${file}"$ | wc -l) > 0 )); then
        if [[ ${file} == */* ]]; then
          r_project=$(awk -F/ '{print $(NF-1)}' <<< ${file})
        else
          r_project=$(basename `pwd`)
        fi
        r_file="${file}"
        r_key="${r_project}:${r_file}"
        local -a services=($(yq '.services | keys | .[]' $file))
        r_services=$(IFS=,; echo "${services[*]}")
        g_entries[${r_key}]="${r_services}${g_entries[${r_key}]:+,}${g_entries[${r_key}]}"

        local merged=$(echo "${g_entries[${r_key}]}" | tr ',' '\n' | sort -u | paste -sd,)
        r_services="${merged}"
        g_entries[${r_key}]=${r_services}
        g_entry_keys+=(${r_key})
        logs_services="${r_services}"
      fi
      [[ -n ${logs_services} ]] && { echo "${logs_txt}${logs_services}"; continue; }
    fi
  done

  if (( ${#g_entry_keys[@]} == 0 )); then
    printf "[%-5s] %s\n" "ERROR" "target is empty. check available list."
    printf " : %s\n" "'${SCRIPT_NM} list'"
    exit
  fi
}

fn_process() {
  local -i tot=${#g_entry_keys[@]}
  local -i idx
  for idx in $(seq 1 $tot); do
    local key=${g_entry_keys[$((idx-1))]}
    local project="${key%:*}"
    local compose_file="${key#*:}"
    local services="${g_entries[$key]}"
    local env_file="${project:+$project/}.env"

    local -a compose_files=()
    local -a dep_compose_files=()
    for dep_service in $(yq '.services[].depends_on | select(. != null) | keys | .[]' ${compose_file}); do
      for key in ${g_all_entry_keys[@]}; do
        if (( $(echo ${g_all_entries[$key]} | grep -o ${dep_service} | wc -l) > 0 )); then
          if [[ ${key#*:} != ${compose_file} ]]; then
            dep_compose_files=(${key#*:})
          fi
          break
        fi
      done
    done
    compose_files+=(${compose_file})
    compose_files+=(${dep_compose_files[@]})
    
    cat <<-EOF
* [${idx}/${tot}] ${key}
  project    : ${project}
  services   : ${services}
  env        : ${env_file}
  compose    : ${compose_file}
  depends_on : ${dep_compose_files[@]:-(none)}
EOF

    case "${p_command}" in
      start|stop|up|down)
        exec_compose "${p_command}" "${project}" "${services}" "${compose_files[*]}"
        ;;
      restart)
        exec_compose "stop" "${project}" "${services}" "${compose_files[*]}"
        exec_compose "start" "${project}" "${services}" "${compose_files[*]}"
        ;;
      recreate)
        exec_compose "down" "${project}" "${services}" "${compose_files[*]}"
        exec_compose "up" "${project}" "${services}" "${compose_files[*]}"
        ;;
    esac
  done

  ## execute 'logs'
  case "${p_command}" in
    logs)
      sleep 0.3
      exec_compose "logs" "${project}" "${services}"
      ;;
    start|restart|up|recreate)
      if [[ ${p_logs_y} == "y" ]]; then
        sleep 0.5
        exec_compose "logs" "${project}" "${services}"
      fi
      ;;
  esac
}

fn_entries
fn_process
# -- main
