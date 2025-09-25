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
- Usage  $SCRIPT_NM [Dockerfile(s)]

OPTIONS:
  --registry  docker registry domain
              e.g '$SCRIPT_NM --registry ${PRIVATE_REGISTRY}'
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
    --) ;;
    *)
      argv+=($1)
      ;;
  esac
  shift
done
# -- options

declare registry="${o_registry:-$PRIVATE_REGISTRY}"

[ -z "${registry}" ] && { echo "registry must not empty."; exit 1; }


declare all_list=(Dockerfile_*)

list() {
  echo "## choose"
  declare dockerfile_list=()
  declare -i idx=0
  for f in ${all_list[@]}; do
    if [[ " ${argv[@]} " =~ " ${f} " ]]; then
      printf "(*) %s. %-s\n" $((idx+1)) "${f}"
      dockerfile_list+=("$f")
    else
      printf "    %s. %-s\n" $((idx+1)) "${f}"
    fi
    ((idx++))
  done
}

execute() {
  local dockerfile="$1"

  local _tmp=${dockerfile#*_}
  local image=${_tmp%_*}
  local tag=${_tmp#*_}

  printf "## build: ${dockerfile}\n"
  docker build -f ${dockerfile} -t ${registry}/${image}:${tag} .
  docker push ${registry}/${image}:${tag}
  docker rmi ${registry}/${image}:${tag}
  echo ""
}

if [[ -z "${dockerfile_list[@]}" ]]; then
  while true; do
    list
    echo -n "(number or filename): "
    read input
    if [ $input -le ${#all_list[@]} ]; then
      declare -i idx=$((input-1))
      execute "${all_list[$idx]}"
    else
      for f in "${all_list[@]}"; do
        case "$f" in
          *$input)
            execute "${all_list[$idx]}"
            ;;
        esac
        break
      done
    fi
  done
else
  list
  for dockerfile in "${dockerfile_list[@]}"; do
    execute "${dockerfile}"
  done
fi
