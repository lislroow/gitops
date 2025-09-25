#!/usr/bin/env bash
BASEDIR=$(cd $(dirname $0) && pwd -P)
SCRIPT_NM="${0##*/}"
PRIVATE_REGISTRY="docker.mgkim.net"

up="\033[A"
clean="\033[K"
end="\033[E"

# usage
function USAGE {
  cat << EOF
- Usage  $SCRIPT_NM [OPTIONS]

OPTIONS:
  -f          Name of the Dockerfile
              e.g '$SCRIPT_NM -f Dockerfile_scouter-server_1.0'
  --registry  docker registry domain
              e.g '$SCRIPT_NM --registry ${PRIVATE_REGISTRY}'
EOF
  exit 1
}
# //usage


# options
declare o_registry
declare o_dockerfile
OPTIONS="f:"
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
    -f)
      o_dockerfile="$2"
      shift
      ;;
    --) ;;
    *)
      argv+=($1)
      ;;
  esac
  shift
done
# -- options

declare registry="${o_registry:-$PRIVATE_REGISTRY}"
declare image=""
declare tag=""

[ -z "${registry}" ] && { echo "registry must not empty."; exit 1; }

dockerfile_list=(Dockerfile_*)
declare -i idx=0
for f in ${dockerfile_list[@]}; do
  if [ "${o_dockerfile}" == "${f}" ]; then
    printf "(*) %s. %-s\n" "${idx}" "${f}"
  else
    printf "    %s. %-s\n" "${idx}" "${f}"
  fi
  ((idx++))
done

if [ -z "${o_dockerfile}" ]; then
  while true; do
    echo -n "choose (number or filename): "
    read input
    if [ $input -le ${#dockerfile_list[@]} ]; then
      o_dockerfile=${dockerfile_list[$input]}
      break
    else
      for f in ${dockerfile_list[@]}; do
        case "$f" in
          *$input)
            o_dockerfile="$f"
            ;;
        esac
        break
      done
    fi
  done
fi

_tmp=${o_dockerfile#*_}
image=${_tmp%_*}
tag=${_tmp#*_}



# main
printf "## build\n"
docker build -f ${o_dockerfile} -t ${registry}/${image}:${tag} .

echo ""

printf "## deploy\n"
printf "### deploy: push image \n"
docker push ${registry}/${image}:${tag}
printf "### deploy: remove image \n"
docker rmi ${registry}/${image}:${tag}
echo ""
# -- main
