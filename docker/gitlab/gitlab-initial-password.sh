#!/usr/bin/env bash
BASEDIR=$(cd $(dirname $0) && pwd -P)
SCRIPT_NM="${0##*/}"


# usage
function USAGE {
  cat << EOF
- Usage  $SCRIPT_NM

EOF
  exit 1
}
# //usage


# -- options
OPTIONS=""
LONGOPTIONS=""
opts=$(getopt --options "${OPTIONS}" \
              --longoptions "${LONGOPTIONS}" \
              -- "$@" )
eval set -- "${opts}"
while true; do
  [ -z "$1" ] && break
  
  case "$1" in
    *)
      argv+=($1)
      ;;
  esac
  shift
done
# -- options

# check
container="gitlab"
passwd_file=/etc/gitlab/initial_root_password
r_running=$(docker inspect --format '{{.State.Running}}' ${container})
[ "${r_running}" == "true" ] && echo "not running '${container}'" | exit 1
# -- check


# main
echo "check: ${container}:${passwd_file}"
r_password=$(docker exec -it ${container} cat ${passwd_file} | grep '^Password' | sed 's/.*: //')
[ $? -ne 0 ] && { echo "It's wrong. ${r_password}"; exit 1; }
echo "user: root, initial-password: ${r_password}"
# -- main
