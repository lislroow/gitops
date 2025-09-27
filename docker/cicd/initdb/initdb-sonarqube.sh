#!/usr/bin/env bash

set -e

if ! psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -tAc "SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = '${postgres_sonarqube_user}'" | grep -q 1; then
  psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "CREATE ROLE ${postgres_sonarqube_user} LOGIN PASSWORD '${postgres_sonarqube_password}';"
fi

if ! psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -tAc "SELECT 1 FROM pg_database WHERE datname = '${postgres_sonarqube_db}'" | grep -q 1; then
  psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "CREATE DATABASE ${postgres_sonarqube_db} OWNER ${postgres_sonarqube_user};"
fi

psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "GRANT ALL PRIVILEGES ON DATABASE ${postgres_sonarqube_db} TO ${postgres_sonarqube_user};"
