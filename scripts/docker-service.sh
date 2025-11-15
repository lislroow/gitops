#!/usr/bin/env bash
BASEDIR=$(cd $(dirname $0) && pwd -P)
SCRIPT_NM="${0##*/}"

shopt -s globstar nullglob

# usage
function USAGE {
  cat << EOF
- Usage  $SCRIPT_NM COMMAND [targets]
COMMAND:
  ls        print service list
  ps        print service process list
  restart   'restart'

EOF
  exit 1
}
# //usage

declare -a g_all_entries=($(docker service ls --format '{{.Name}}'))
function LIST {
  # local -i cnt=${#g_all_entries[@]}
  # local -i f2_len=$(printf "%s\n" ${g_all_entries[@]} | wc -L)
  # local FORMAT="  %2s  %-$((f3_len+2))s\n"
  # local output=$(printf "${FORMAT}" "NO" "SERVICE")
  # output+="\n"
  # for ((i=0; i<cnt; i++)); do
  #   local svc=${g_all_entries[$i]}
  #   output+=$(printf "${FORMAT}" "$((i+1))" "${svc}")
  #   output+="\n"
  # done
  # echo -e "${output}"
  docker service ls
}

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
    --)
      ;;
    *)
      argv+=($1)
      ;;
  esac
  shift
done


# init
declare p_command=${argv[0]}
init() {
  if [[ -z ${p_command} ]]; then
    printf "[%-5s] %s\n\n" "ERROR" "COMMAND is required"
    USAGE
  fi

  case "${p_command}" in
    ls)
      LIST
      exit
      ;;
    ps|restart)
      ;;
    *)
      printf "[%-5s] %s\n" "ERROR" "invalid COMMAND. '${p_command}'"
      printf " : %s\n" "'${SCRIPT_NM} -h'"
      exit
      ;;
  esac
}
init


function exec_ps {
  local target=$1
  printf "\n* ${target}\n"
  docker service ps ${target}
  printf "\n"
}

exec_restart() {
  declare -a targets=($*)
  for SVC in ${targets[@]}; do
    docker service update --force $SVC
  done
}

declare -i cnt=0
while true; do
  m_entries=()
  
  (( $cnt == 0 )) && { LIST; ((cnt++)) } 
  echo ""
  echo -n "(NAME, all='process all', ls='print list'): "
  read input

  case "${input}" in
    all)
      m_entries=(${g_all_entries[@]})
      ;;
    ls)
      LIST
      continue
      ;;
    n|N)
      exit
      ;;
    *)
      for val in ${input[@]}; do
        entry=$(printf "%s\n" "${g_all_entries[@]}" | grep "${val}")
        [[ -z ${entry} ]] && { echo "'${val}' is not matched."; continue; }
        m_entries+=(${entry})
      done
      ;;
  esac

  case ${p_command} in
    ps)
      for entry in ${m_entries[@]}; do
        exec_ps "${entry}"
      done
      ;;
    restart)
      exec_restart "${m_entries[*]}"
      ;;
  esac
done
