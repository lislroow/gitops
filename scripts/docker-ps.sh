#!/usr/bin/env bash
BASEDIR=$(cd $(dirname $0) && pwd -P)
SCRIPT_NM="${0##*/}"

shopt -s globstar nullglob

# usage
function USAGE {
  cat << EOF
- Usage  $SCRIPT_NM [COLUMNS]

COLUMNS:
  id      : CONTAINER ID 'format: {{.Id}}'
  image   : IMAGE 'format: {{.Image}}'
  status  : STATUS 'format: {{.Status}}'
  name    : NAMES 'format: {{.Names}}'
  ports   : PORTS 'format: {{.Ports}}'

EOF
  exit 1
}
# -- usage

# options
declare p_logs_y
declare OPTIONS="h"
declare LONGOPTIONS=""
declare opts=$(getopt --options "${OPTIONS}" \
                      --longoptions "${LONGOPTIONS}" \
                      -- "$@" )
eval set -- "${opts}"
while true; do
  [[ -z $1 ]] && break
  
  case "$1" in
    -h|--help)
      USAGE
      ;;
    --)
      ;;
    --*)
      printf "[%-5s] %s\n" "ERROR" "invalid option: '$1'"
      exit
      ;;
    *)
      argv+=($1)
      ;;
  esac
  shift
done
# -- options

declare -a p_columns=("${argv[@]}")


COL_ID="{{.ID}}"
COL_IMAGE="{{.Image}}"
COL_STATUS="{{.Status}}"
COL_NAME="{{.Names}}"
COL_PORTS="{{.Ports}}"

o_cols=""
for ((i=0; i<${#p_columns[@]}; i++)); do
  case ${p_columns[$i]} in
    id)
      o_cols+="${COL_ID}"
      ;;
    image)
      o_cols+="${COL_IMAGE}"
      ;;
    status)
      o_cols+="${COL_STATUS}"
      ;;
    name)
      o_cols+="${COL_NAME}"
      ;;
    ports)
      o_cols+="${COL_PORTS}"
      ;;
  esac
  (( $i < ${#p_columns[@]} -1 )) && o_cols+="\t"
done
echo "o_cols: ${o_cols}"

if (( ${#p_columns[@]} == 0 )); then
  o_cols="${COL_ID}\t${COL_IMAGE}\t${COL_NAME}\t${COL_STATUS}"
fi

docker ps --format "table ${o_cols}"
