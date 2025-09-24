#!/usr/bin/env bash

set -e

if ! psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -tAc "SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = '${n8n_postgres_user}'" | grep -q 1; then
  psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "CREATE ROLE ${n8n_postgres_user} LOGIN PASSWORD '${n8n_postgres_password}';"
fi

if ! psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -tAc "SELECT 1 FROM pg_database WHERE datname = '${n8n_postgres_db}'" | grep -q 1; then
  psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "CREATE DATABASE ${n8n_postgres_db} OWNER ${n8n_postgres_user};"
fi

psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "GRANT ALL PRIVILEGES ON DATABASE ${n8n_postgres_db} TO ${n8n_postgres_user};"


# psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" <<-EOSQL
# -- 1. n8n role(사용자) 생성
# DO
# \$do\$
# BEGIN
#   IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = '${n8n_postgres_user}') THEN
#     CREATE ROLE ${n8n_postgres_user} LOGIN PASSWORD '${n8n_postgres_password}';
#   END IF;
# END
# \$do\$;
# -- 2. n8n DB 생성
# DO
# \$do\$
# BEGIN
#   IF NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = '${n8n_postgres_db}') THEN
#     CREATE DATABASE ${n8n_postgres_db} OWNER ${n8n_postgres_user};
#   END IF;
# END
# \$do\$;
# -- 3. n8n DB에 모든 권한 부여 (OWNER 가 이미 모든 권한을 가지지만, 명시적으로 부여)
# GRANT ALL PRIVILEGES ON DATABASE ${n8n_postgres_db} TO ${n8n_postgres_user};
# EOSQL


# psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" <<-EOSQL
# CREATE ROLE ${n8n_postgres_user} LOGIN PASSWORD '${n8n_postgres_password}';
# CREATE DATABASE ${n8n_postgres_db} OWNER ${n8n_postgres_user};
# GRANT ALL PRIVILEGES ON DATABASE ${n8n_postgres_db} TO ${n8n_postgres_user};
# EOSQL
