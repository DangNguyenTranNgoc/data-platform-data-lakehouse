#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

MODULE_NAME=$(basename $0)
POSTGRES_DEFAULT_DB=postgres
AIRFLOW__DATABASE_HOST=${AIRFLOW__DATABASE_HOST:-postgres}
AIRFLOW__DATABASE_USER=${AIRFLOW__DATABASE_USER:-postgres}
AIRFLOW__DATABASE_PASSWORD=${AIRFLOW__DATABASE_PASSWORD:-postgres}
AIRFLOW__DATABASE_DB=${AIRFLOW__DATABASE_DB:-airflow}
AIRFLOW__DATABASE_PORT=${AIRFLOW__DATABASE_PORT:-5432}

_logger() {
    local level=""
    local tag=""
    local file="/proc/1/fd/1"
    local msg=""
    while [ $# -gt 0 ]; do
        case "$1" in
            -l)
                level=$2
                shift
                shift
                ;;
            -f)
                file=$2
                shift
                shift
                ;;
            *)
                break
                ;;
        esac
    done
    # Printing...
    local dt="$(date +"%Y-%m-%d %T %Z")"
    case $level in
        error|ERROR)
            msg="${dt} [ERROR]     "
            ;;
        warn|WARN)
            msg="${dt} [WARN]      "
            ;;
        info|INFO)
            msg="${dt} [INFO]      "
            ;;
        debug|DEBUG)
            msg="${dt} [DEBUG]     "
            ;;
        verbose|VERBOSE)
            msg="${dt} [VERBOSE]   "
            ;;
        *)
            msg="${dt} [INFO]      "
            ;;
    esac
    echo "${msg} ${@}" >> "${file}"
}

error() {
    if [ $# -eq 1 ];then
        _logger -l ERROR "${@}"
    fi
}

warn() {
    if [ $# -eq 1 ];then
        _logger -l WARN "${@}"
    fi
}

info() {
    if [ $# -eq 1 ];then
        _logger -l INFO "${@}"
    fi
}

debug() {
    if [ $# -eq 1 ];then
        _logger -l DEBUG "${@}"
    fi
}

verbose() {
    if [ $# -eq 1 ];then
        _logger -l VERBOSE "${@}"
    fi
}

check_postgressql_connection() {
  max_retry=5
  is_connect=false
  info "Check connection to SQL server [${3}:${4}]"
  for (( i=1; $i<=$max_retry; i++ )); do
    pg_isready -q -d "postgres://${1}:${2}@${3}:${4}"
    if [[ $? == 0 ]]; then
        info "PostgreSQL server is connected"
        return
    else
        warn "Couldn't connect to PostgreSQL server, retrying $i/$max_retry"
        is_connect=false
    fi
    sleep 5
  done
  if [[ $is_connect == false ]]; then
    error "Couldn't connect to PostgreSQL server"
    return
  fi
}

check_database() {
  psql -lqt "postgres://${1}:${2}@${3}:${4}/${POSTGRES_DEFAULT_DB}" | cut -d \| -f 1 | grep -qw "${5}"
  if [[ $? == 0 ]]; then
    info "Database [${5}] is existed"
    return 0
  fi
  error "Database [${5}] is not existed on PostgreSQL server"
  return 1
}

create_database() {
    psql -q "postgres://${1}:${2}@${3}:${4}/${5}" -c "CREATE DATABASE ${6};"
    if [[ $? == 0 ]]; then
        info "Database [${6}] is created"
        return 0
    fi
    error "Couldn't create database [${6}]"
    return 1
}

create_database_if_not_existed() {
    result=$(check_database ${1} ${2} ${3} ${4} ${5})
    if [[ $result == 1 ]]; then
        info "Create database [${5}]"
        if [[ $(create_database ${1} ${2} ${3} ${4} "${POSTGRES_DEFAULT_DB}" ${5}) != 0 ]]; then
            return 1
        fi
        info "Database [${5}] is created"
    fi
    return 0
}

airflow_init() {
  check_postgressql_connection "${AIRFLOW__DATABASE_USER}" "${AIRFLOW__DATABASE_PASSWORD}" "${AIRFLOW__DATABASE_HOST}" "${AIRFLOW__DATABASE_PORT}"
  create_database_if_not_existed "${AIRFLOW__DATABASE_USER}" "${AIRFLOW__DATABASE_PASSWORD}" "${AIRFLOW__DATABASE_HOST}" "${AIRFLOW__DATABASE_PORT}" "${AIRFLOW__DATABASE_DB}"
  if [[ -z "${AIRFLOW_UID}" ]]; then
    msg=$(cat <<EOF
\033[1;33mWARNING!!!: AIRFLOW_UID not set!\e[0m
If you are on Linux, you SHOULD follow the instructions below to set
AIRFLOW_UID environment variable, otherwise files will be owned by root.
For other operating systems you can get rid of the warning with manually created .env file:
    See: https://airflow.apache.org/docs/apache-airflow/stable/howto/docker-compose/index.html#setting-the-right-airflow-user

EOF
)
    echo -e "${msg}"
    warn "${msg}"
  fi
  one_meg=1048576
  mem_available=$(($(getconf _PHYS_PAGES) * $(getconf PAGE_SIZE) / one_meg))
  cpus_available=$(grep -cE 'cpu[0-9]+' /proc/stat)
  disk_available=$(df / | tail -1 | awk '{print $4}')
  warning_resources="false"
  if (( mem_available < 4000 )) ; then
    msg=$(cat <<EOF
\033[1;33mWARNING!!!: Not enough memory available for Docker.\e[0m
At least 4GB of memory required. You have $(numfmt --to iec $((mem_available * one_meg)))

EOF
)
    warning_resources="true"
    echo -e "${msg}"
    warn "${msg}"
  fi
  if (( cpus_available < 2 )); then
    msg=$(cat <<EOF
\033[1;33mWARNING!!!: Not enough CPUS available for Docker.\e[0m
At least 2 CPUs recommended. You have ${cpus_available}

EOF
)
    warning_resources="true"
    echo -e "${msg}"
    warn "${msg}"
  fi
  if (( disk_available < one_meg * 10 )); then
    msg=$(cat <<EOF
\033[1;33mWARNING!!!: Not enough Disk space available for Docker.\e[0m
At least 10 GBs recommended. You have $(numfmt --to iec $((disk_available * 1024 )))

EOF
)
    warning_resources="true"
    echo -e "${msg}"
    warn "${msg}"
  fi
  if [[ ${warning_resources} == "true" ]]; then
    msg=$(cat <<EOF
\033[1;33mWARNING!!!: You have not enough resources to run Airflow (see above)!\e[0m
Please follow the instructions to increase amount of resources available:
   https://airflow.apache.org/docs/apache-airflow/stable/howto/docker-compose/index.html#before-you-begin

EOF
)
    echo -e "${msg}"
    warn "${msg}"
  fi
  mkdir -p /sources/logs /sources/dags /sources/plugins
  chown -R "${AIRFLOW_UID}:0" /sources/{logs,dags,plugins}
  exec /entrypoint airflow version
}

usage() { 
    cat <<EOF 
Usage: 

airflow-init  Init process for Airflow

EOF
}

if [[ $# -eq 0 ]];then
    usage
    exit 1
fi

subcommand="${1}"
case $subcommand in
    "" | "-h" | "--help")
        usage
        exit 1;
        ;;
    "airflow-init")
        if declare -f "airflow_init" >/dev/null 2>&1; then
            shift
            airflow_init
        else
            echo "Function $1 is missing" >&2
            exit 1
        fi
        exit 0
        ;;
    *)
        echo "Error: '$subcommand' is unknown command." >&2
        usage
        exit 1
        ;;
esac
