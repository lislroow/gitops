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
  status    service status

OPTIONS:
  --logs    logs after 'start|restart|up|recreate'

EOF
  exit 1
}

function LIST {
  declare -a files=(**/*.yml)
  declare -i file_cnt=${#files[@]}
  # printf "* available list (${file_cnt})\n"
  
  local output=""
  declare -i f3_len=$(printf "%s\n" ${files[@]} | wc -L)
  local FORMAT="  %2s  %-7s  %-$((f3_len+2))s  %s\n"
  output+=$(printf "${FORMAT}" "NO" "PROJECT" "FILE" "SERVICES")
  output+="\n"
  for i in $(seq 0 $((file_cnt-1))); do
    yml_file=${files[$i]}
    if [ $(echo "${yml_file}" | grep -o '/' | wc -l) -eq 0 ]; then
      project="$(basename $PWD)"
    else
      project="$(awk -F/ '{print $(NF-1)}' <<< ${yml_file})"
    fi
    declare -a services=($(yq '.services | keys | .[]' $yml_file))
    service_list="$(IFS=,; echo "${services[*]}")"
    output+=$(printf "${FORMAT}" "$((i+1))" "${project}" "${yml_file}" "${service_list}")
    output+="\n"
  done
  echo -e "${output}"
  exit
}
# //usage

# options
declare p_logs_y
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
  printf " : %s\n" "'${SCRIPT_NM} -h'"
  exit
fi

case "${p_command}" in
  list)
    LIST
    exit
    ;;
esac

declare -a p_targets=("${argv[@]:1}")
if [ ${#p_targets[@]} -eq 0 ]; then
  printf "[%-5s] %s\n" "ERROR" "service or project is required. check available list."
  printf " : %s\n" "'${SCRIPT_NM} -h' or '${SCRIPT_NM} list'"
  exit
fi

declare -A g_all_entries
declare -a g_all_entry_keys=()

fn_all_entries() {
  declare -a all_yml_list=(**/*.yml)
  if (( ${#all_yml_list[@]} > 0 )); then
    declare r_project=""
    declare r_file=""
    declare r_key=""
    declare r_services=""
    for yml_file in ${all_yml_list[@]}; do
      if [[ "${yml_file}" == */* ]]; then
        r_project=$(awk -F/ '{print $(NF-1)}' <<< ${yml_file})
      else
        r_project=$(basename `pwd`)
      fi
      r_file=${yml_file}
      r_key="${r_project}:${r_file}"
      declare -a services=($(yq '.services | keys | .[]' $yml_file))
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
  declare -a services=($(IFS=,; read -ra services <<< "$3"; echo ${services[@]}))
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
  if [[ "${command}" != "logs"* ]]; then
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
    declare r_project=""
    declare r_file=""
    declare r_key=""
    declare r_services=""
    
    declare -a yml_list=(**/${target}/*.yml)
    if (( ${#yml_list[@]} > 0 )); then
      logtxt=$(printf "[INFO] filter by %-12s: > " "project-name")
      declare _services=""
      for yml_file in ${yml_list[@]}; do
        r_project=${target}
        r_file=${yml_file}
        r_key="${r_project}:${r_file}"
        declare -a services=($(yq '.services | keys | .[]' $yml_file))
        r_services=$(IFS=,; echo "${services[*]}")
        g_entries[${r_key}]="${r_services}"

        declare merged=$(echo "${g_entries[${r_key}]}" | tr ',' '\n' | sort -u | paste -sd,)
        g_entries[${r_key}]=${merged}
        g_entry_keys+=(${r_key})
        
        [ -n "${project_services}" ] && project_services+=","
        project_services+="${r_services}"
      done
      if [ -n "${project_services}" ]; then
        echo "${logtxt}${project_services}"
        continue
      fi
    else
      logtxt=$(printf "[INFO] filter by %-12s: > " "service-name")
      for key in ${g_all_entry_keys[@]}; do
        r_key="${key}"
        declare -a arr=($(IFS=,; read -ra arr <<< ${g_all_entries[$r_key]}; echo "${arr[@]}"))
        if (( $(printf "%s\n" ${arr[@]} | grep -o ^"${target}"$ | wc -l) > 0 )); then
          r_services="${target}"
          g_entries[${r_key}]="${r_services}${g_entries[${r_key}]:+,}${g_entries[${r_key}]}"
          declare merged=$(echo "${g_entries[${r_key}]}" | tr ',' '\n' | sort -u | paste -sd,)
          r_services="${merged}"
          g_entries[${r_key}]=${r_services}
          g_entry_keys+=(${r_key})
          break
        fi
      done
      if [ -n "${r_services}" ]; then
        echo "${logtxt}${r_services}"
        continue
      fi

      yml_file="${target}"
      logtxt=$(printf "[INFO] filter by %-12s: > " "file-name")
      if (( $(printf "%s\n" ${!g_all_entries[@]} | grep -o ":${yml_file}"$ | wc -l) > 0 )); then
        if [[ "${yml_file}" == */* ]]; then
          r_project=$(awk -F/ '{print $(NF-1)}' <<< ${yml_file})
        else
          r_project=$(basename `pwd`)
        fi
        r_file=${yml_file}
        r_key="${r_project}:${r_file}"
        declare -a services=($(yq '.services | keys | .[]' $yml_file))
        r_services=$(IFS=,; echo "${services[*]}")
        g_entries[${r_key}]="${r_services}${g_entries[${r_key}]:+,}${g_entries[${r_key}]}"

        declare merged=$(echo "${g_entries[${r_key}]}" | tr ',' '\n' | sort -u | paste -sd,)
        r_services="${merged}"
        g_entries[${r_key}]=${r_services}
        g_entry_keys+=(${r_key})
      fi
      if [ -n "${r_services}" ]; then
        echo "${logtxt}${r_services}"
        continue
      fi
    fi
  done

  if (( ${#g_entry_keys[@]} == 0 )); then
    printf "[%-5s] %s\n" "ERROR" "target is empty. check available list."
    printf " : %s\n" "'${SCRIPT_NM} list'"
    exit
  fi
}

fn_process() {
  declare -i tot=${#g_entry_keys[@]}
  declare -i idx
  for idx in $(seq 1 $tot); do
    local key=${g_entry_keys[$((idx-1))]}
    local project="${key%:*}"
    local compose_file="${key#*:}"
    local services="${g_entries[$key]}"
    local env_file="${project:+$project/}.env"

    declare -a compose_files=()
    declare -a dep_compose_files=()
    for dep_service in $(yq '.services[].depends_on | select(. != null) | keys | .[]' ${compose_file}); do
      for key in ${g_all_entry_keys[@]}; do
        if (( $(echo ${g_all_entries[$key]} | grep -o ${dep_service} | wc -l) > 0 )); then
          if [ "${key#*:}" != "${compose_file}" ]; then
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
      if [ "${p_logs_y}" == "y" ]; then
        sleep 0.5
        exec_compose "logs" "${project}" "${services}"
      fi
      ;;
  esac
}

fn_entries
fn_process
# -- main
