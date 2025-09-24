#!/usr/bin/env bash

set -e

if ! psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -tAc "SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = '${keycloak_postgres_user}'" | grep -q 1; then
  psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "CREATE ROLE ${keycloak_postgres_user} LOGIN PASSWORD '${keycloak_postgres_password}';"
fi

if ! psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -tAc "SELECT 1 FROM pg_database WHERE datname = '${keycloak_postgres_db}'" | grep -q 1; then
  psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "CREATE DATABASE ${keycloak_postgres_db} OWNER ${keycloak_postgres_user};"
fi

psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "GRANT ALL PRIVILEGES ON DATABASE ${keycloak_postgres_db} TO ${keycloak_postgres_user};"
