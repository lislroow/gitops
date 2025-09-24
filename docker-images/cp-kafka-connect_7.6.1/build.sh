#!/usr/bin/env bash
BASEDIR=$(cd $(dirname $0) && pwd -P)
SCRIPT_NM="${0##*/}"
PRIVATE_REGISTRY="docker.mgkim.net"


# usage
function USAGE {
  cat << EOF
- Usage  $SCRIPT_NM COMMAND
COMMAND:
  build     build image
  deploy    build & deploy image

OPTIONS:
  --registry  docker registry domain
              e.g '$SCRIPT_NM [build | deploy] --registry ${PRIVATE_REGISTRY}'

EOF
  exit 1
}
# //usage

# options
declare o_registry
OPTIONS=""
LONGOPTIONS="registry:"
opts=$(getopt --options "${OPTIONS}" \
              --longoptions "${LONGOPTIONS}" \
              -- "$@" )
eval set -- "${opts}"
while true; do
  [ -z "$1" ] && break
  
  case "$1" in
    --registry)
      o_registry="$2"
      shift
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


registry="${o_registry:-$PRIVATE_REGISTRY}"
image="cp-kafka-connect"
tag="7.6.1"

[ -z "${registry}" ] && { echo "registry must not empty."; exit 1; }


build() {
  printf "## build\n"
  docker build -t ${registry}/${image}:${tag} .
  echo ""
}

deploy() {
  printf "## deploy\n"
  
  printf "### deploy: push image \n"
  docker push ${registry}/${image}:${tag}
  printf "### deploy: remove image \n"
  docker rmi ${registry}/${image}:${tag}
  echo ""
}

# main
command=${argv[1]}

case "${command}" in
  build)
    build
    ;;
  deploy)
    build
    deploy
    ;;
  *)
    USAGE
    ;;
esac
# -- main
