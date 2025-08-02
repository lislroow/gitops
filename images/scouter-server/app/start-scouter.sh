#!/bin/bash
BASEDIR=$( cd "$( dirname "$0" )" && pwd -P )

if [[ `uname -s` == "MINGW64_NT-"* ]]; then
  export JAVA_HOME='/c/develop/tools/corretto/corretto-8'
  export PATH="$JAVA_HOME/bin:$PATH"
fi

CLASSPATH="${BASEDIR}"
for file in $BASEDIR/lib/*.jar; do
  CLASSPATH="${CLASSPATH}:${file}"
done
CLASSPATH="${CLASSPATH}:${BASEDIR}/scouter-server-boot.jar"

#echo "classpath=" $CLASSPATH

java -Xmx1024m -classpath $CLASSPATH -Dscouter.config=conf/scouter.conf scouter.boot.Boot 
