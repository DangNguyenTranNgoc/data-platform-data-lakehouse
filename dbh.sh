#!/bin/bash
# An helper for Data Platfom project

MODULE_NAME=$(basename $0)
WORK_DIR=$(PWD)

create_folder() {
    read -r -d '' help <<EOF 
Safe create folder

Usage: 

  -f, --folder      Path to the folder

EOF
    if [[ "${@}" -eq 0 ]];then
        echo "${help}"
        exit 1
    fi
    local valid_args=$(getopt -o f:h --long folder:,help -- "$@")
    if [[ $? -ne 0 ]]; then
        echo "${help}"
        exit 1;
    fi

    eval set -- "$valid_args"

    while [ : ]; do
        case "${1}" in
          -f | --folder)
            folder_path="${2}"
            shift 2
            ;;
          -h | --help)
            echo "${help}"
            exit 0
            ;;
          --) shift;
            break
            ;;
        esac
    done

    local now=$(date +"%Y_%m_%d-%H_%M_%S")
    safe_create_folder | tee "${WORK_DIR}/${MODULE_NAME}_generate_folder_${now}.log"

}

safe_create_folder() {
    local maximum=10
    local parent=$(dirname "${1}")
    local dname=$(basename "${1}")
    if [[ ! -d "${1}" ]]; then
        mkdir "${1}"
        echo ${1}
    else
        for (( i=0; i<$maximum; i++ ));do
            local folder="${parent}/${dname}_${i}/"
            if [[ ! -d "${folder}" ]]; then
                mkdir "${folder}"
                echo ${folder}
                break
            fi
        done
    fi
}

usage() { 
    cat <<EOF 
Usage: 

create-folder  Safe create new folder

EOF
}

subcommand=$1
case $subcommand in
    "" | "-h" | "--help")
        usage
        exit 1;
        ;;
    "create-folder")
        if declare -f "create_folder" >/dev/null 2>&1; then
            shift
            create_folder "$@"
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

