#!/bin/bash

show_help() {
    echo "Usage: $(basename $0) [OPTIONS] [APPLICATION]"
    echo ""
    echo "Options:"
    echo "  dev               Set environment to 'dev'"
    echo "  int               Set environment to 'int'"
    echo "  prod              Set environment to 'prod'"
    echo ""
    echo "Application:"
    echo "  -[app1, app2, ...]  Specify the application for which logs are to be retrieved"
}

# File containing the array content
file_path="app_services.txt"

get_argument_value() {
    local arg_name="$1"
    shift   # Shift to remove the first argument (arg_name)

    local found=false
    local next_argument=""

    while [ $# -gt 0 ]; do
        if [ "$1" == "$arg_name" ]; then
            found=true
        elif [ "$found" == true ]; then
            next_argument="$1"
            break
        fi
        shift
    done

    echo "$next_argument"
}


logWebAppService() {
    theAppService=$1
    theResourceGroup=$2
    theSubscription=$3
    theOutput=$4
    theFilter=""
    if [ "$#" -ge 5 ]; then
        theFilter=$5
    fi
    

    echo "Get Logs for: "
    echo "   SUBCRIPTION....: $theSubscription"
    echo "   RESOURCE_GROUP.: $theResourceGroup"
    echo "   APP_SERVICE....: $theAppService"
    echo "   OUTPUT.........: $theOutput"
    echo "   FILTER.........: $theFilter"

    cmd="az webapp log tail --name ${theAppService} --resource-group ${theResourceGroup} --subscription ${theSubscription} --provider 'application'"

    captureOut=""
    grep=""
    if [[ "${theFilter}" != "" ]]; then
       captureOut="2>&1"
       grep="| grep ${theFilter}"
    fi

    logFileName=""
    if [[ "${theOutput}" == "file" ]]; then        
        captureOut="2>&1"
        logFileName="| tee /c/temp/logs/${theAppService}.log"
    fi


    echo -e "\n--> [CMD] $cmd ${logFileName}\n"
    bash -c "$cmd ${captureOut} ${grep} ${logFileName}" 

    return $?
}

set -e
set -u

ARGS=$*
CURRENT_DIR=$(dirname $(realpath $0))

if [[ "${ARGS}" == *-h* || "${ARGS}" == *--help* ]]; then
    show_help
    exit 0
fi

echo "#########################################"
echo "#"
echo "#  CURRENT_DIR.......: ${CURRENT_DIR}"
echo "#  ARGS..............: ${ARGS}"
echo "#"
echo "#########################################"
echo ""

ENV="${1}"
APPLICATION="${2}"
cmd=""
OUTPUT="console"
FILTER=""

if [[ $ENV != "dev" && $ENV != "int" && $ENV != "prod" ]]; then
    echo "Error: First argument must be 'dev', 'int', or 'prod'"
    show_help
    exit 0
fi
if [[ $APPLICATION == "" ]]; then
    echo "Error: Second argument cannot be empty"
    show_help
    exit 0
fi
if [[ "${ARGS}" == *-file* ]]; then
    OUTPUT="file"
fi

if [[ "${ARGS}" == *-filter* ]]; then
    FILTER=$(get_argument_value "-filter" "$@")
fi

# Declare the array
declare -A APPS

# Read the file line by line and assign each line to the APPS array
while IFS= read -r line || [[ -n "$line" ]]; do
    # Split the line into key and value using whitespace as delimiter
    key=$(echo "$line" | awk '{print $1}')
    value=$(echo "$line" | awk '{$1=""; print $0}')
    APPS["$key"]="$value"
done < "$file_path"

IFS=' ' read -r SUBCRIPTION RESOURCE_GROUP APP_SERVICE <<< "${APPS[$ENV.$APPLICATION]}"

logWebAppService ${APP_SERVICE} ${RESOURCE_GROUP} ${SUBCRIPTION} ${OUTPUT} ${FILTER}
return_code=$?
exit $return_code
