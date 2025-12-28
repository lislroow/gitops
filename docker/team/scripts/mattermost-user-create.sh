#!/usr/bin/env bash
BASEDIR=$(cd $(dirname $0) && pwd -P)
SCRIPT_NM="${0##*/}"


# usage
function USAGE {
  cat << EOF
- Usage  $SCRIPT_NM OPTIONS

OPTIONS:
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
OPTIONS="h"
LONGOPTIONS="system-admin"
opts=$(getopt --options "${OPTIONS}" \
              --longoptions "${LONGOPTIONS}" \
              -- "$@" )
eval set -- "${opts}"
while true; do
  [ -z "$1" ] && break
  
  case "$1" in
    -h)
      USAGE
      ;;
    --system-admin)
      o_sysadm="true"
      ;;
    --)
      ;;
    *)
      argv+=($1)
      ;;
  esac
  shift
done
o_email=${argv[0]}
o_username=${argv[1]}
o_password=${argv[2]}
# -- options


# input
while [ -z ${o_email} ]; do
  printf " > email: "
  read o_email
done

while [ -z ${o_username} ]; do
  printf " > username: "
  read o_username
done

while [ -z ${o_password} ]; do
  printf " > password: "
  read o_password
done
# -- input

cat <<EOF
create mattermost user
  - email: ${o_email}
  - username: ${o_username}
  - password: ${o_password}
EOF

printf " > correct? [a: abort] "
read yn
if [[ ${yn} == "a" ]]; then
  printf "creation aborted\n"
  exit
fi

# check
container="mattermost"
running=$(docker inspect --format '{{.State.Running}}' ${container})
[ ${running} != "true" ] && { echo "not running '${container}'"; exit 1; }
# -- check

# main
docker exec -it mattermost mmctl user create \
  --local \
  --email "${o_email}" \
  --username "${o_username}" \
  --password "${o_password}" \
  ${sysadm:+--system-admin}
# -- main