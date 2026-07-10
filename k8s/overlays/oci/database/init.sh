#!/bin/sh
set -eu

ADMIN_PASSWORD="$(cat /mnt/secrets-store/admin-password)"
APP_PASSWORD="$(cat /mnt/secrets-store/app-password)"
export PGSSLMODE="${DB_SSLMODE:-require}"

attempt=0
until PGPASSWORD="$ADMIN_PASSWORD" pg_isready \
  --host="$DB_HOST" --port="$DB_PORT" --username="$DB_ADMIN_USER" --dbname=postgres; do
  attempt=$((attempt + 1))
  if [ "$attempt" -ge 30 ]; then
    echo "PostgreSQL não ficou disponível dentro do prazo." >&2
    exit 1
  fi
  sleep 5
done

PGPASSWORD="$ADMIN_PASSWORD" psql \
  --host="$DB_HOST" \
  --port="$DB_PORT" \
  --username="$DB_ADMIN_USER" \
  --dbname=postgres \
  --set=ON_ERROR_STOP=1 \
  --set=app_user="$DB_APP_USER" \
  --set=app_password="$APP_PASSWORD" \
  --set=db_name="$DB_NAME" <<'SQL'
SELECT format('CREATE ROLE %I LOGIN PASSWORD %L', :'app_user', :'app_password')
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = :'app_user') \gexec
SELECT format('ALTER ROLE %I WITH LOGIN PASSWORD %L', :'app_user', :'app_password') \gexec
SELECT format('CREATE DATABASE %I OWNER %I', :'db_name', :'app_user')
WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = :'db_name') \gexec
SELECT format('ALTER DATABASE %I OWNER TO %I', :'db_name', :'app_user') \gexec
SQL

PGPASSWORD="$APP_PASSWORD" psql \
  --host="$DB_HOST" \
  --port="$DB_PORT" \
  --username="$DB_APP_USER" \
  --dbname="$DB_NAME" \
  --set=ON_ERROR_STOP=1 \
  --file="/database-init/$SCHEMA_FILE"

echo "Banco $DB_NAME e schema $SCHEMA_FILE inicializados com sucesso."
