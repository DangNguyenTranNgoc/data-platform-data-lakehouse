#!/bin/bash
# Init DB for Hive Metastore, Airflow ...
# on PostgeSQL
set -o errexit
set -o nounset
set -o pipefail

source ./helper.sh

# Check connection to PostgreSQL
# Ex: check_db_connection ${POSTGRES_USER} ${POSTGRES_PASSWORD} ${POSTGRES_HOST} ${POSTGRES_PORT}

# Check if metastore db is existed
# Ex: create_database_if_not_existed ${POSTGRES_USER} ${POSTGRES_PASSWORD} ${POSTGRES_HOST} ${POSTGRES_PORT} "postgres"

# Execute SQL file
# Ex: exec_sql_file ${POSTGRES_USER} ${POSTGRES_PASSWORD} ${POSTGRES_HOST} ${POSTGRES_PORT} "test_db" "/opt/init.sql"


# Done, expose a hook for further cmd
echo ""
exec "$@"