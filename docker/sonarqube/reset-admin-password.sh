#!/usr/bin/env bash
BASEDIR=$(cd $(dirname $0) && pwd -P)

export $(grep -v '^#' ${BASEDIR}/.env | xargs)

CONTAINER='sonarqube-postgres'
SQL="UPDATE users SET crypted_password=NULL, salt=NULL WHERE login='admin';"

cat <<-EOF
  CONTAINER : ${CONTAINER}
  SQL       : ${SQL}

[warning] password reset not working!!
EOF
exit 1
# docker exec -i "${CONTAINER}" \
#   psql -U "${sonarqube_postgres_user}" -d "${sonarqube_postgres_db}" -c "${SQL}"
