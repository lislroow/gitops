#!/usr/bin/env bash
BASEDIR=$(cd $(dirname $0) && pwd -P)
SCRIPT_NM="${0##*/}"

# usage
function USAGE {
  cat << EOF
- Usage  $SCRIPT_NM COMMAND
Commands:
  start     Start scouter-host
  stop      Stop scouter-host
  restart   Stop and Start scouter-host
  status    'ps -ef ...' command
  logs      'tail -f ... log' command

Options:
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
declare o_local
OPTIONS="vd"
LONGOPTIONS="local"
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
    --local)
      o_local="y"
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
  echo "## start scouter-host"

  # default
  local log_dir="/logs/apm/scouter-host"
  local server_host
  case "${o_local}" in
    y)
      server_host="localhost"
      ;;
    *)
      server_host="mgkim.net"
      ;;
  esac
  
  [ ! -d "${BASEDIR}/conf" ] && { echo "create directory: '${BASEDIR}/conf'"; mkdir ${BASEDIR}/conf; }
  local net_collector_ip="${server_host}"
  local net_tcp_listen_port="${net_tcp_listen_port:-6100}"
  local net_udp_listen_port="${net_udp_listen_port:-6100}"
  cat <<-EOF | sed 's/^[[:space:]]*//' > ${BASEDIR}/conf/scouter.conf
    log_dir=${log_dir}
    net_collector_ip=${net_collector_ip}
    net_collector_udp_port=${net_tcp_listen_port}
    net_collector_tcp_port=${net_udp_listen_port}
    cpu_warning_pct=80
    cpu_fatal_pct=85
    cpu_check_period_ms=60000
    cpu_fatal_history=3
    cpu_alert_interval_ms=300000
    disk_warning_pct=88
    disk_fatal_pct=92

EOF

  local CLASSPATH="${BASEDIR}/scouter-host.jar"
  local pid_files=(${BASEDIR}/*.scouter)
  [ ${#pid_files[@]} -gt 0 ] && { echo "remove pid files: ${pid_files[@]}"; rm -rf ${pid_files[@]}; }

  local lib_dir="/data/apm/scouter-host-lib"
  if [ "${o_daemon}" == "y" ]; then
    nohup ${JAVA_HOME}/bin/java -DSCOUTER_HOST \
      -Dscouter.config=${BASEDIR}/conf/scouter.conf \
      -Dnet_collector_ip=${net_collector_ip} \
      -classpath $CLASSPATH \
      scouter.boot.Boot ${lib_dir}> /dev/null 2>&1 &
  else
    ${JAVA_HOME}/bin/java -DSCOUTER_HOST \
      -Dscouter.config=${BASEDIR}/conf/scouter.conf \
      -Dnet_collector_ip=${net_collector_ip} \
      -classpath $CLASSPATH \
      scouter.boot.Boot ${lib_dir}
  fi
}

stop() {
  echo "## stop scouter-host"
  pid_files=(${BASEDIR}/*.scouter)
  [ ${#pid_files[@]} -gt 0 ] && { echo "remove pid files: ${pid_files[@]}"; rm -rf ${pid_files[@]}; }
}

status() {
  echo "## status scouter-host"
  pid=$(ps -ef | grep -v grep | grep SCOUTER_HOST | awk '{ print $2 }')
  [ -z "${pid}" ] && { echo "scouter-host is not running."; exit; }
  
  elapsed=$(ps -p ${pid} -o etime | tail -n +2 | awk '{ print $1 }')
  process=$(ps -ef | grep -v grep | grep SCOUTER_HOST | awk '{ for (i=1; i<=NF; i++) { if ($i ~ /java$/) { print $i; break; } }}')
  
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

logs() {
  tail -f /logs/apm/scouter-host/agent-$(date +%Y%m%d).log
}

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
