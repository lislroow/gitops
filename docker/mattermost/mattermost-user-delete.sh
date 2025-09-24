#!/usr/bin/env bash
BASEDIR=$(cd $(dirname $0) && pwd -P)
SCRIPT_NM="${0##*/}"


# usage
function USAGE {
  cat << EOF
- Usage  $SCRIPT_NM username1 [username2 ...]

Options:
  --confirm       delete no confirm

EOF
  exit 1
}
# //usage


# -- options
declare o_username
declare o_confirm
OPTIONS=""
LONGOPTIONS="confirm"
opts=$(getopt --options "${OPTIONS}" \
              --longoptions "${LONGOPTIONS}" \
              -- "$@" )
eval set -- "${opts}"
while true; do
  [ -z "$1" ] && break
  
  case "$1" in
    --confirm)
      o_confirm="true"
      ;;
    *)
      argv+=($1)
      ;;
  esac
  shift
done
o_usernames=("${argv[@]:1}")
# -- options


# validate
[ "${#o_usernames[@]}" -eq 0 ] && {echo "require 'username'"; USAGE;}
# -- validate

# check
container="mattermost"
running=$(docker inspect --format '{{.State.Running}}' ${container})
[ "${running}" == "true" ] && {echo "not running '${container}'"; exit 1;}
# -- check

# main
for username in ${o_usernames[@]}; do
  docker exec -it mattermost mmctl user delete "${username}" \
    --local \
    ${o_confirm:+--confirm}
done
# -- main
