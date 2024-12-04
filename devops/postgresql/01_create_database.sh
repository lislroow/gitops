#!/bin/bash

mapfile -t LIST < <(cat <<- EOF

mattermost
sonarqube

EOF
)

USER_NAME=postgres

for item in ${LIST[@]}; do
  DATABASE_NAME=$item
  psql -U $USER_NAME -tc "SELECT 1 FROM pg_database WHERE datname = '${DATABASE_NAME}'" | grep -q 1 \
    || psql -U $USER_NAME -c "CREATE DATABASE ${DATABASE_NAME}"
done
