#!/usr/bin/env bash
BASEDIR=$(cd $(dirname $0) && pwd -P)
SCRIPT_NM="${0##*/}"
PRIVATE_REGISTRY="docker.mgkim.net"

# usage
function USAGE {
  cat << EOF
- Usage  $SCRIPT_NM COMMAND
Commands:
  build     build image
  deploy    build & deploy image

Options:
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
image="scouter-server"
tag="1.0"

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

check() {
  printf "## check client cert files\n"
  printf "   registry: %s\n" "${PRIVATE_REGISTRY}"
  printf "   directory: /etc/docker/certs.d/%s/*\n" "${PRIVATE_REGISTRY}"
  local certs=$(ls /etc/docker/certs2.d/${PRIVATE_REGISTRY}/ 2> /dev/null)
  local pubilc_key
  local private_key
  if [ ${#certs[@]} -gt 0 ]; then
    for file in ${certs[@]}; do
      case "$file" in
        *cert)
          pubilc_key=$(realpath ${file})
          ;;
        *key)
          private_key=$(realpath ${file})
          ;;
      esac
    done
  fi
  printf "   public key : %s\n" "${pubilc_key:-(not found)}"
  printf "   private key: %s\n" "${private_key:-(not found)}"
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
  check)
    check
    ;;
  *)
    USAGE
    ;;
esac
# -- main
