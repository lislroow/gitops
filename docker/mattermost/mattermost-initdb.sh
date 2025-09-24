#!/usr/bin/env bash

set -e

if ! psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -tAc "SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = '${mattermost_postgres_user}'" | grep -q 1; then
  psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "CREATE ROLE ${mattermost_postgres_user} LOGIN PASSWORD '${mattermost_postgres_password}';"
fi

if ! psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -tAc "SELECT 1 FROM pg_database WHERE datname = '${mattermost_postgres_db}'" | grep -q 1; then
  psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "CREATE DATABASE ${mattermost_postgres_db} OWNER ${mattermost_postgres_user};"
fi

psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "GRANT ALL PRIVILEGES ON DATABASE ${mattermost_postgres_db} TO ${mattermost_postgres_user};"
