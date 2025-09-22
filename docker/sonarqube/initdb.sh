#!/usr/bin/env bash

set -e

if ! psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -tAc "SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = '${sonarqube_postgres_user}'" | grep -q 1; then
  psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "CREATE ROLE ${sonarqube_postgres_user} LOGIN PASSWORD '${sonarqube_postgres_password}';"
fi

if ! psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -tAc "SELECT 1 FROM pg_database WHERE datname = '${sonarqube_postgres_db}'" | grep -q 1; then
  psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "CREATE DATABASE ${sonarqube_postgres_db} OWNER ${sonarqube_postgres_user};"
fi

psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "GRANT ALL PRIVILEGES ON DATABASE ${sonarqube_postgres_db} TO ${sonarqube_postgres_user};"
