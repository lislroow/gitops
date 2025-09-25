#!/usr/bin/env bash
BASEDIR=$(cd $(dirname $0) && pwd -P)
SCRIPT_NM="${0##*/}"

# variable
declare network_nm='team_net'
declare env_file="${BASEDIR}/../yml/.env"

# usage
function USAGE {
  cat << EOF
- Usage  $SCRIPT_NM [OPTIONS] [COMMAND]
COMMAND:
  status    status volume, network

OPTIONS:
  --clear   clear all

EOF
  exit 1
}
# //usage


# options
declare o_clear
OPTIONS=""
LONGOPTIONS="clear"
opts=$(getopt --options "${OPTIONS}" \
              --longoptions "${LONGOPTIONS}" \
              -- "$@" )
eval set -- "${opts}"
while true; do
  [ -z "$1" ] && break
  
  case "$1" in
    --clear)
      o_clear="y"
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

clear() {
  echo "## clear"
  echo " * network"
  if docker network ls | grep ${network_nm} > /dev/null; then
    r_network_nm=$(docker network rm ${network_nm})
    if [ "${network_nm}" == "${r_network_nm}" ]; then
      echo "   delete successful: '${network_nm}'"
    else
      echo "   delete fail: '${network_nm}'"
    fi
  else
    echo "   does not exist: '${network_nm}'"
  fi
  echo ""
}

create() {
  echo "## create"
  echo " * network"
  if ! docker network ls | grep ${network_nm} > /dev/null; then
    network_id=$(docker network create ${network_nm} --driver=bridge)
    echo "   created successful: '${network_nm}' (${network_id})"
  else
    echo "   already exist: '${network_nm}'"
  fi
  echo ""

  export $(grep -v '^#' "${env_file}" | xargs)
}

status() {
  echo "## status"
  echo " * status network"
  docker network ls
  echo " * status volume"
  docker volume ls
  echo ""
}

# main
command=${argv[1]}

case "${command}" in
  status)
    status
    ;;
  *)
    if [ "${o_clear}" == "y" ]; then
      clear
    else
      create
    fi
    status
    ;;
esac
# -- main
