#!/bin/bash
# Run manually via psql since postgres was already initialized when this was added:
#   psql -U postgres -c "CREATE USER firefly WITH PASSWORD '<FIREFLY_DB_PASSWORD from postgres/.env>';"
#   psql -U postgres -c "CREATE DATABASE firefly OWNER firefly;"
set -e
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE USER firefly WITH PASSWORD '$FIREFLY_DB_PASSWORD';
    CREATE DATABASE firefly OWNER firefly;
EOSQL
