#!/usr/bin/env bash
BASEDIR=$(cd $(dirname $0) && pwd -P)
SCRIPT_NM="${0##*/}"

# usage
function USAGE {
  cat << EOF
- Usage  $SCRIPT_NM service

EOF
  exit 1
}
# //usage

# options
declare p_logs_y
declare OPTIONS=""
declare LONGOPTIONS=""
declare opts=$(getopt --options "${OPTIONS}" \
                      --longoptions "${LONGOPTIONS}" \
                      -- "$@" )
eval set -- "${opts}"
while true; do
  [[ -z $1 ]] && break
  
  case "$1" in
    --)
      ;;
    *)
      argv+=($1)
      ;;
  esac
  shift
done
# -- options

# init
declare -a p_targets=(${argv[@]})
declare -a g_all_entries=($(docker ps -a --format "{{.ID}}|{{.Names}}"))

if (( ${#argv[@]} == 0)); then
  echo -n "show available list [y] or inspect all [enter] "
  read yn
  if [[ ${yn} == "y" ]]; then
    printf "\n"
    printf "%-15s | %-20s\n" "CONTAINER ID" "NAME"
    printf "%-15s-+-%-20s\n" "---------------" "--------------------"
    for item in "${g_all_entries[@]}"; do
      IFS='|' read -r id name <<< "$item"
      printf "%-15s | %-20s\n" "$id" "$name"
    done
    exit
  fi
fi
# -- init

yq_query=".[] "
if (( ${#p_targets[@]} > 0)); then
  yq_filters_svc=$(printf ".Name == \"/%s\" or " "${p_targets[@]}")
  yq_filters_svc="${yq_filters_svc[@]:0:-4}"
  yq_filters_prj=$(printf ".Config.Labels[\"com.docker.compose.project\"] == \"%s\" or " "${p_targets[@]}")
  yq_filters_prj="${yq_filters_prj[@]:0:-4}"
  yq_filters="select(${yq_filters_svc} or ${yq_filters_prj})"
  yq_query+="| ${yq_filters}"
fi

yq_entries="\""
yq_entries+="\(.Id)"
yq_entries+="|\(.Name)"
yq_entries+='|\(.Config.Image // \"\")'
yq_entries+='|\(.Config.Labels[\"com.docker.compose.project.config_files\"])'
yq_entries+='|\(.Config.Volumes // {} | keys // [] | join(\",\"))'
yq_entries+='|\(.HostConfig.Binds // [] | join(\",\"))'
yq_entries+='|\(.HostConfig.PortBindings | to_entries | map(\"\(.value[0].HostPort)->\(.key)\") | join(\",\"))'
yq_entries+="\""
yq_query+="| ${yq_entries}"

result=($(docker inspect ${g_all_entries[@]%%\|*} | yq -r "${yq_query}" | grep -v '^|'))
for ((i=0; i<${#result[@]}; i++)); do
  IFS='|' read -r id name image compose volumes binds ports <<< ${result[$i]}
  printf "[%d/%d] %s (%s)\n" $((i+1)) ${#result[@]} ${name:1} ${id:0:12}
  if [[ -n ${image} ]]; then
    printf " * image: %s\n" ${image}
  fi
  if [[ -n ${compose} ]]; then
    IFS=',' read -r -a a_compose <<< ${compose}
    if ((${#a_compose[@]} > 1)); then
      printf " * compose\n"
      for ((j=0; j<${#a_compose[@]}; j++)); do
        if (($j == ${#a_compose[@]}-1)); then link_char='└'; else link_char='├'; fi
        printf "   ${link_char} %s\n" ${a_compose[$j]}
      done
    else
      printf " * compose: %s\n" ${compose}
    fi
  fi
  if [[ -n ${volumes} ]]; then
    printf " * volumes\n"
    IFS=',' read -r -a a_vols <<< ${volumes}
    IFS=',' read -r -a a_binds <<< ${binds}
    for ((j=0; j<${#a_vols[@]}; j++)); do
      r_v1='' r_v2='' r_v3=''
      for ((k=0; k<${#a_binds[@]}; k++)); do
        IFS=':' read -r v1 v2 v3 <<< ${a_binds[$k]}
        if [[ ${v2} == ${a_vols[$j]} ]]; then
          r_v1=${v1} r_v2=${v2} r_v3=${v3}
          break
        fi
      done
      
      if (($j == ${#a_vols[@]}-1)); then link_char='└'; else link_char='├'; fi
      if [[ -n ${r_v1} ]] && [[ -n ${r_v2} ]] && [[ -n ${r_v3} ]]; then
        printf "   ${link_char} %s > %s\n" ${r_v1} ${r_v2}
      else
        printf "   ${link_char} - > %s\n" ${r_v2}
      fi
    done
  fi
  if [[ -n ${ports} ]]; then
    printf " * ports\n"
    IFS=',' read -r -a a_ports <<< ${ports}
    for ((j=0; j<${#a_ports[@]}; j++)); do
      if (($j == ${#a_ports[@]}-1)); then link_char='└'; else link_char='├'; fi
      printf "   ${link_char} %s\n" ${a_ports[$j]}
    done
  fi
  
  printf "\n"

done