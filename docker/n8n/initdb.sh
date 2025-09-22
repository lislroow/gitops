#!/usr/bin/env bash

set -e

if ! psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -tAc "SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = '${postgres_n8n_user}'" | grep -q 1; then
  psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "CREATE ROLE ${postgres_n8n_user} LOGIN PASSWORD '${postgres_n8n_password}';"
fi

if ! psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -tAc "SELECT 1 FROM pg_database WHERE datname = '${postgres_n8n_db}'" | grep -q 1; then
  psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "CREATE DATABASE ${postgres_n8n_db} OWNER ${postgres_n8n_user};"
fi

psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "GRANT ALL PRIVILEGES ON DATABASE ${postgres_n8n_db} TO ${postgres_n8n_user};"


# psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" <<-EOSQL
# -- 1. n8n role(사용자) 생성
# DO
# \$do\$
# BEGIN
#   IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = '${postgres_n8n_user}') THEN
#     CREATE ROLE ${postgres_n8n_user} LOGIN PASSWORD '${postgres_n8n_password}';
#   END IF;
# END
# \$do\$;
# -- 2. n8n DB 생성
# DO
# \$do\$
# BEGIN
#   IF NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = '${postgres_n8n_db}') THEN
#     CREATE DATABASE ${postgres_n8n_db} OWNER ${postgres_n8n_user};
#   END IF;
# END
# \$do\$;
# -- 3. n8n DB에 모든 권한 부여 (OWNER 가 이미 모든 권한을 가지지만, 명시적으로 부여)
# GRANT ALL PRIVILEGES ON DATABASE ${postgres_n8n_db} TO ${postgres_n8n_user};
# EOSQL


# psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" <<-EOSQL
# CREATE ROLE ${postgres_n8n_user} LOGIN PASSWORD '${postgres_n8n_password}';
# CREATE DATABASE ${postgres_n8n_db} OWNER ${postgres_n8n_user};
# GRANT ALL PRIVILEGES ON DATABASE ${postgres_n8n_db} TO ${postgres_n8n_user};
# EOSQL
