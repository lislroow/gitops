#!/usr/bin/env bash
BASEDIR=$( cd "$( dirname "$0" )" && pwd -P )

declare env_file="${BASEDIR}/../.env"
export $(grep -v '^#' "${env_file}" | xargs)

export PGPASSWORD="${postgres_password}"
(
  curl -k -L https://nexus.mgkim.net/repository/raw-hosted/sql/prototype-schema-postgres.sql
  curl -k -L https://nexus.mgkim.net/repository/raw-hosted/sql/prototype-data.sql
) | docker exec -i postgres psql -U "${postgres_user}" -d "${postgres_db}"
