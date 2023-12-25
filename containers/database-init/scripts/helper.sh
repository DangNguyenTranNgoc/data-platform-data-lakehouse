#!/bin/bash
# An helper includes many util functions

POSTGRES_DEFAULT_DB=postgres

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

test_log() {
    verbose "Verbose message"
    debug "Debug message"
    info "Info message"
    warn "Warning message"
    error "Error message"
}

check_db_connection() {
    max_retry=5
    is_connect=false
    i=0
    info "Check connection to PostgreSQL server [${3}:${4}]"
    for (( i=1; $i<=$max_retry; i++ )); do
        if [[ $(pg_isready -q -d "postgres://${1}:${2}@${3}:${4}") == 0 ]]; then
            info "PostgreSQL server is connected"
            echo 0
            return
        else
            warn "Couldn't connect to PostgreSQL server, retrying $i/$max_retry"
            is_connect=false
        fi
        sleep 5
    done
    if [[ $is_connect == false ]]; then
        error "Couldn't connect to PostgreSQL server"
        echo 1
        return
    fi
}

check_database() {
    psql -lqt "postgres://${1}:${2}@${3}:${4}/${POSTGRES_DEFAULT_DB}" | cut -d \| -f 1 | grep -qw "${5}"
    if [[ $? == 0 ]]; then
        info "Database [${5}] is existed"
        echo 0
        return
    fi
    error "Database [${5}] is not existed on PostgreSQL server"
    echo 1
    return
}

create_database() {
    psql -q "postgres://${1}:${2}@${3}:${4}/${5}" -c "CREATE DATABASE ${6};"
    if [[ $? == 0 ]]; then
        info "Database [${6}] is created"
        echo 0
        return
    fi
    error "Couldn't create database [${6}]"
    echo 1
    return
}

create_database_if_not_existed() {
    result=$(check_database ${1} ${2} ${3} ${4} ${5})
    if [[ $result == 1 ]]; then
        info "Create database [${5}]"
        if [[ $(create_database ${1} ${2} ${3} ${4} "${POSTGRES_DEFAULT_DB}" ${5}) != 0 ]]; then
            echo 1
            return
        fi
        info "Database [${5}] is created"
    fi
    echo 0
    return
}

exec_sql_file() {
    if [[ -f "${6}" && "${${6}: -4}" == ".sql" ]];then
        error "Invalid file [${6}]"
        echo 1
        return
    fi
    if [[ $(check_database ${1} ${2} ${3} ${4} ${5}) == 1 ]]; then
        info "Execute SQL query: [${6}]"
        psql -q "postgres://${1}:${2}@${3}:${4}/${5}" -f ${6}
        if [[ $? == 0 ]];then
            info "Success"
            echo 0
            return
        fi
        error "Fail to execute sql file [${6}]"
        echo 1
        return
    fi
}
