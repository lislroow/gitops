#!/usr/bin/env bash
BASEDIR=$(cd $(dirname $0) && pwd -P)
SCRIPT_NM="${0##*/}"
PRIVATE_REGISTRY="docker.mgkim.net"

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

function LIST {
  local -a dockerfile_list=(Dockerfile*)
  local -i file_cnt=${#dockerfile_list[@]}
  local -i idx=0

  local -i f2_len=$(printf "%s\n" ${dockerfile_list[@]} | wc -L)
  local FORMAT="  %2s  %-$((f2_len+2))s %s\n"
  local output=$(printf "${FORMAT}" "NO" "FILE" "IMAGE")
  output+="\n"
  for i in $(seq 0 $((file_cnt-1))); do
    local file="${dockerfile_list[$i]}"
    IFS='_' read -r dfile image tag <<< "${file}"
    output+=$(printf "${FORMAT}" "$((i+1))" "${file}" "${PRIVATE_REGISTRY}/${image}:${tag}")
    output+="\n"
  done
  echo -e "${output}"
}
# //usage


# options
declare p_registry
declare p_list_y
declare p_name
declare p_build_only_y
declare p_rmi_y
declare OPTIONS="l"
declare LONGOPTIONS="registry:,list,name:,build-only,rmi"
declare opts=$(getopt --options "${OPTIONS}" \
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
    -l|--list)
      p_list_y="y"
      ;;
    --name)
      p_name="$2"
      shift
      ;;
    --build-only)
      p_build_only_y="y"
      ;;
    --rmi)
      p_rmi_y="y"
      ;;
    --) ;;
    *)
      argv+=($1)
      ;;
  esac
  shift
done
# -- options

# init
declare registry="${p_registry:-$PRIVATE_REGISTRY}"
[ -z "${registry}" ] && { echo "registry must not empty."; exit 1; }

declare -a g_all_entries=(Dockerfile*)

declare -a p_targets=("${argv[@]}")
if (( ${#p_targets[@]} > 0)) && [ "${p_targets[0]}" == "list" ]; then
  LIST
  exit
fi

declare -a m_entries=($(printf "%s\n" "${g_all_entries[@]}" | \
  grep -E $(IFS='|'; echo "^(${p_targets[*]})$")
))
# -- init

# functions
build() {
  local dockerfile="$1"
  local image="$2"
  local tag="$3"

  printf "## build: ${dockerfile}\n"
  docker build -f ${dockerfile} -t ${registry}/${image}:${tag} .
  if [ "${p_build_only_y}" != "y" ]; then
    docker push ${registry}/${image}:${tag}
  fi
  if [ "${p_rmi_y}" == "y" ]; then
    docker rmi ${registry}/${image}:${tag}
  fi
  docker image prune -f
  echo ""
}

build_entries() {
  local dockerfiles=("$1")
  # printf " > %s\n" ${dockerfiles[@]}

  local -i tot=${#m_entries[@]}
  local -i idx
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
# -- functions


# main
if [ ${#m_entries[@]} -eq 0 ]; then
  if [ ${#g_all_entries[@]} -eq 1 ]; then
    dockerfile=${g_all_entries[0]}
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
    
    LIST
    echo ""
    echo -n "(NO or FILE, a=all): "
    read input

    if [ "${input}" == "a" ]; then
      m_entries=(${g_all_entries[@]})
      build_entries "${m_entries[*]}"
      continue
    fi

    for val in ${input[@]}; do
      if [[ "${val}" =~ ^[0-9]+$ ]]; then
        [ ${val} -gt ${#g_all_entries[@]} ] && { echo "'${val}' is out of index."; continue; }
        m_entries+=("${g_all_entries[$val-1]}")
      else
        entry=$(printf "%s\n" "${g_all_entries[@]}" | grep "${val}")
        [ "${entry}" == "" ] && { echo "'${val}' is not matched."; continue; }
        m_entries+=(${entry})
      fi
    done

    build_entries "${m_entries[*]}"
  done
else
  build_entries "${m_entries[*]}" # [caution]
fi
# -- main
