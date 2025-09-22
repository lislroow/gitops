#!/usr/bin/env bash
BASEDIR=$(cd $(dirname $0) && pwd -P)

export $(grep -v '^#' "${BASEDIR}/.env" | xargs)

if [ -n "${postgres_non_root_user:-}" ] && [ -n "${postgres_non_root_user:-}" ]; then
  psql -v ON_ERROR_STOP=1 --username "${postgres_user}" --dbname "${postgres_db}" <<-EOSQL
    CREATE USER ${postgres_non_root_user} WITH PASSWORD '${postgres_non_root_user}';
    GRANT ALL PRIVILEGES ON DATABASE ${postgres_db} TO ${postgres_non_root_user};
    GRANT CREATE ON SCHEMA public TO ${postgres_non_root_user};
  EOSQL
else
  echo "SETUP INFO: No Environment variables given!"
fi
