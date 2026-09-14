#!/bin/bash
# Run manually via psql since postgres was already initialized when this was added:
#   podman exec postgres psql -U postgres -c "CREATE ROLE memos LOGIN PASSWORD '<MEMOS_DB_PASSWORD>';"
#   podman exec postgres psql -U postgres -c "CREATE DATABASE memos OWNER memos;"
set -e
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE USER memos WITH PASSWORD '${MEMOS_DB_PASSWORD}';
    CREATE DATABASE memos OWNER memos;
EOSQL
