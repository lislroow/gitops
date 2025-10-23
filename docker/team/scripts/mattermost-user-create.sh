#!/usr/bin/env bash
BASEDIR=$(cd $(dirname $0) && pwd -P)
SCRIPT_NM="${0##*/}"


# usage
function USAGE {
  cat << EOF
- Usage  $SCRIPT_NM OPTIONS

OPTIONS:          (*) required
  --email         (*) email
  --username      (*) username
  --password      (*) password
  --system-admin      system admin role (if --system-admin is empty > 'member')

EOF
  exit 1
}
# //usage


# -- options
declare o_email
declare o_username
declare o_password
declare o_sysadm
OPTIONS=""
LONGOPTIONS="email:,username:,password:,system-admin"
opts=$(getopt --options "${OPTIONS}" \
              --longoptions "${LONGOPTIONS}" \
              -- "$@" )
eval set -- "${opts}"
while true; do
  [ -z "$1" ] && break
  
  case "$1" in
    --email)
      o_email="$2"
      shift
      ;;
    --username)
      o_username="$2"
      shift
      ;;
    --password)
      o_password="$2"
      shift
      ;;
    --system-admin)
      o_sysadm="true"
      ;;
    *)
      argv+=($1)
      ;;
  esac
  shift
done
# -- options


# validate
[ -z "${o_email}" ] && { echo "require 'email'"; USAGE; }
[ -z "${o_username}" ] && { echo "require 'username'"; USAGE; }
[ -z "${o_password}" ] && { echo "require 'password'"; USAGE; }
# -- validate

# check
container="mattermost"
running=$(docker inspect --format '{{.State.Running}}' ${container})
[ "${running}" != "true" ] && { echo "not running '${container}'"; exit 1; }
# -- check

# main
docker exec -it mattermost mmctl user create \
  --local \
  --email "${o_email}" \
  --username "${o_username}" \
  --password "${o_password}" \
  ${sysadm:+--system-admin}
# -- main