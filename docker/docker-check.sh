#!/usr/bin/env bash
BASEDIR=$(cd $(dirname $0) && pwd -P)
SCRIPT_NM="${0##*/}"

# usage
function USAGE {
  cat << EOF
- Usage  $SCRIPT_NM COMMAND
COMMAND:
  network   'create' and 'start'

EOF
  exit 1
}
# //usage

# options
OPTIONS=""
LONGOPTIONS=""
opts=$(getopt --options "${OPTIONS}" \
              --longoptions "${LONGOPTIONS}" \
              -- "$@" )
eval set -- "${opts}"
while true; do
  [ -z "$1" ] && break
  
  case "$1" in
    --)
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
# -- init

# functions
check_network() {
  local all_projects=($(cd ${BASEDIR} && find . -maxdepth 1 -type d | tail -n +2 | sed 's/.\///'))
  printf "## check network\n"
  declare -a creatableList=()
  for prj in ${all_projects[@]}; do
    local net_id name driver scope
    read net_id name driver scope <<< $(docker network ls | grep "${prj}")
    local exist=$([ -n "$net_id" ] && echo "O" || echo "X")
    [ "${exist}" == "X" ] && creatableList+=("${prj}_net")
    printf "  [%s]%-10s %-12s %-8s %s\n" "${exist}" "${prj}_net" "${net_id:--}" "${driver:--}" "${scope:--}"
  done

  if [ ${#creatableList[@]} -gt 0 ]; then
    printf "> creatable list\n"
    printf "  docker network create %s --driver=bridge\n" ${creatableList[@]}
  fi
  # echo "docker network create ${prject}_net --driver=bridge"
}
# -- functions

# variables
# -- variables

# main
case "${p_command}" in
  network)
    check_network
    ;;
esac
# -- main
