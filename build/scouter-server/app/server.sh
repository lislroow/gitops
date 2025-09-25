#!/usr/bin/env bash
BASEDIR=$(cd $(dirname $0) && pwd -P)
SCRIPT_NM="${0##*/}"

# usage
function USAGE {
  cat << EOF
- Usage  $SCRIPT_NM COMMAND
COMMAND:
  start     Start scouter-server
  stop      Stop scouter-server
  restart   Stop and Start scouter-server
  status    'ps -ef ...' command
  logs      'tail -f ... log' command

OPTIONS:
  -d        startup daemon mode (nohup ... > /dev/null 2>&1 &)
            e.g '$SCRIPT_NM start -d'
  -v        verbose
            e.g '$SCRIPT_NM status -v'

EOF
  exit 1
}
# //usage

# options
declare o_daemon
declare o_verbose
OPTIONS="vd"
LONGOPTIONS=""
opts=$(getopt --options "${OPTIONS}" \
              --longoptions "${LONGOPTIONS}" \
              -- "$@" )
eval set -- "${opts}"
while true; do
  [ -z "$1" ] && break
  
  case "$1" in
    -d)
      o_daemon="y"
      ;;
    -v)
      o_verbose="y"
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

# requirement
if [ -x /bin/java ]; then
  JAVA_HOME=$(readlink -f /bin/java | sed 's/\/bin\/java//')
else
  JAVA_HOME="/usr/lib/corretto-8"
  [ ! -d "${JAVA_HOME}" ] && { echo "JAVA_HOME=${JAVA_HOME} does not exist."; exit 1; }
fi
# -- requirement

start() {
  echo "## start scouter-server"

  # default
  net_tcp_listen_port="${net_tcp_listen_port:-6101}"
  net_udp_listen_port="${net_udp_listen_port:-6101}"
  db_dir="${db_dir:-./data}"
  log_dir="${log_dir:-./logs}"
  cat <<-EOF | sed 's/^[[:space:]]*//' > ${BASEDIR}/conf/scouter.conf
    net_tcp_listen_port=${net_tcp_listen_port}
    net_udp_listen_port=${net_udp_listen_port}
    db_dir=${db_dir}
    log_dir=${log_dir}
EOF

  # -- default

  ## classpath
  # [ style 1 ]
  # CLASSPATH="${BASEDIR}"
  # for file in $BASEDIR/lib/*.jar; do
  #   CLASSPATH="${CLASSPATH}:${file}"
  # done

  # [ style 2 ]
  CLASSPATH="$BASEDIR:$(printf '%s:' "$BASEDIR"/lib/*.jar)"
  CLASSPATH="${CLASSPATH%:}"

  # [ style 3 ]
  # CLASSPATH="$BASEDIR:$(find "$BASEDIR/lib" -name '*.jar' -printf '%p:' | tr -d '\n')"
  # CLASSPATH="${CLASSPATH%:}"
  ## -- classpath

  CLASSPATH="${CLASSPATH}:${BASEDIR}/scouter-server-boot.jar"
  pid_files=(${BASEDIR}/*.scouter)
  [ ${#pid_files[@]} -gt 0 ] && { echo "remove pid files: ${pid_files[@]}"; rm -rf ${pid_files[@]}; }

  if [ "${o_daemon}" == "y" ]; then
    nohup ${JAVA_HOME}/bin/java -DSCOUTER_SERVER \
      -Dscouter.config=${BASEDIR}/conf/scouter.conf \
      -Dnet_tcp_listen_port=${net_tcp_listen_port} \
      -Dnet_udp_listen_port=${net_udp_listen_port} \
      -Ddb_dir=${db_dir} \
      -Dlog_dir=${log_dir} \
      -classpath $CLASSPATH \
      scouter.boot.Boot > /dev/null 2>&1 &
  else
    ${JAVA_HOME}/bin/java -DSCOUTER_SERVER \
      -Dscouter.config=${BASEDIR}/conf/scouter.conf \
      -Dnet_tcp_listen_port=${net_tcp_listen_port} \
      -Dnet_udp_listen_port=${net_udp_listen_port} \
      -Ddb_dir=${db_dir} \
      -Dlog_dir=${log_dir} \
      -classpath $CLASSPATH \
      scouter.boot.Boot
  fi
}

stop() {
  echo "## stop scouter-server"
  pid_files=(${BASEDIR}/*.scouter)
  [ ${#pid_files[@]} -gt 0 ] && { echo "remove pid files: ${pid_files[@]}"; rm -rf ${pid_files[@]}; }
}

status() {
  pid=$(ps -ef | grep -v grep | grep SCOUTER_SERVER | awk '{ print $2 }')
  elapsed=$(ps -p ${pid} -o etime | tail -n +2 | awk '{ print $1 }')
  process=$(ps -ef | grep -v grep | grep SCOUTER_SERVER | awk '{ for (i=1; i<=NF; i++) { if ($i ~ /java$/) { print $i; break; } }}')
  
  if [ "${o_verbose}" == "y" ]; then
    ps -ef | grep -v grep | grep ${pid}
    netstat -ntplu | grep ${pid}
  fi

  printf "%-10s %-10s %s\n" "${pid}" "${elapsed}" "${process}"
  cat <<-EOF
${BASEDIR}/conf/scouter.conf
$(cat ${BASEDIR}/conf/scouter.conf)
EOF
}

# logs() {

# }

# main
command=${argv[1]}

case "${command}" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  restart)
    stop
    start
    ;;
  status)
    status
    ;;
  logs)
    logs
    ;;
  *)
    USAGE
    ;;
esac
# -- main
