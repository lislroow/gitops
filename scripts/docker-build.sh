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
declare p_registry
declare p_name
declare p_build_only
declare p_rmi
OPTIONS=""
LONGOPTIONS="registry:,name:,build-only,rmi"
opts=$(getopt --options "${OPTIONS}" \
              --longoptions "${LONGOPTIONS}" \
              -- "$@" )
eval set -- "${opts}"
while true; do
  [ -z "$1" ] && break
  
  case "$1" in
    --registry)
      p_registry="$2"
      shift
      ;;
    --name)
      p_name="$2"
      shift
      ;;
    --build-only)
      p_build_only="y"
      ;;
    --rmi)
      p_rmi="y"
      ;;
    --) ;;
    *)
      argv+=($1)
      ;;
  esac
  shift
done
# -- options

declare registry="${p_registry:-$PRIVATE_REGISTRY}"

[ -z "${registry}" ] && { echo "registry must not empty."; exit 1; }


list_entries() {
  echo "## choose"
  declare dockerfile_list=()
  declare -i idx=0
  for f in ${m_all_entries[@]}; do
    if [[ " ${argv[@]} " =~ " ${f} " ]]; then
      printf "(*) %s. %-s\n" $((idx+1)) "${f}"
      dockerfile_list+=("$f")
    else
      printf "    %s. %-s\n" $((idx+1)) "${f}"
    fi
    ((idx++))
  done
}

build() {
  local dockerfile="$1"
  local image="$2"
  local tag="$3"

  printf "## build: ${dockerfile}\n"
  docker build -f ${dockerfile} -t ${registry}/${image}:${tag} .
  if [ "${p_build_only}" != "y" ]; then
    docker push ${registry}/${image}:${tag}
  fi
  if [ "${p_rmi}" == "y" ]; then
    docker rmi ${registry}/${image}:${tag}
  fi
  docker image prune -f
  echo ""
}

build_entries() {
  local dockerfiles=("$1")
  # printf " > %s\n" ${dockerfiles[@]}

  declare -i tot=${#m_entries[@]}
  declare -i idx
  for dockerfile in ${m_entries[@]}; do
    local _tmp=${dockerfile#*_}
    local image=${_tmp%_*}
    local tag=${_tmp#*_}

    ((idx++))
    cat <<-EOF
  * [${idx}/${tot}] dockerfile '${dockerfile}'
    image     : ${p_registry:-docker.mgkim.net}/${image}:${tag}

EOF
    build "${dockerfile}" "${image}" "${tag}"
  done
}

declare m_all_entries=($(ls Dockerfile*))
declare -a p_targets=("${argv[@]}")
declare -a m_entries=($(printf "%s\n" "${m_all_entries[@]}" | \
  grep -E $(IFS='|'; echo "^(${p_targets[*]})$")
))

if [ ${#m_entries[@]} -eq 0 ]; then
  if [ ${#m_all_entries[@]} -eq 1 ]; then
    dockerfile=${m_all_entries[0]}
    if [ -n "${p_name}" ]; then
      if [ $(echo "${p_name}" | grep -o '_' | wc -l) -ne 1 ]; then
        echo "invalid --name value. '${p_name}', e.g) {image}_{tag}"
        exit
      fi
      image=${p_name%_*}
      tag=${p_name#*_}
    else
      if [ $(echo "${dockerfile}" | grep -o '_' | wc -l) -ne 2 ]; then
        echo "invalid Dockerfile name. '${dockerfile}', e.g) Dockerfile_{image}_{tag}"
        exit
      fi
      _tmp=${dockerfile#*_}
      image=${_tmp%_*}
      tag=${_tmp#*_}
    fi
    build "${dockerfile}" "${image}" "${tag}"
    exit
  fi
  while true; do
    m_entries=()
    
    list_entries
    echo -n "(number or filename, a=all): "
    read input

    if [ "${input}" == "a" ]; then
      m_entries=(${m_all_entries[@]})
      build_entries "${m_entries[*]}"
      continue
    fi

    for val in ${input[@]}; do
      if [[ "${val}" =~ ^[0-9]+$ ]]; then
        [ ${val} -gt ${#m_all_entries[@]} ] && { echo "'${val}' is out of index."; continue; }
        m_entries+=("${m_all_entries[$val-1]}")
      else
        entry=$(printf "%s\n" "${m_all_entries[@]}" | grep "${val}")
        [ "${entry}" == "" ] && { echo "'${val}' is not matched."; continue; }
        m_entries+=(${entry})
      fi
    done

    build_entries "${m_entries[*]}"
  done
else
  build_entries "${m_entries[*]}" # [caution]
fi
