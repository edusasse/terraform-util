#!/bin/bash

set -e
set -u

ARGS=$*
CURRENT_DIR=`dirname $(realpath $0)`

echo "#####################################################"
echo "#"
echo "#  CURRENT_DIR.......: ${CURRENT_DIR}"
echo "#  ARGS..............: ${ARGS}"
echo "#"
echo "# Usage:"
echo "#       set-env.sh <app-env-file.sh>"
echo "#"
echo "# Example:"
echo "#       set-env.sh tmc-dev-env.sh"
echo "#"
echo "#####################################################"
echo ""

if [ "$#" -ne 1 ] || [ ! -f "$1" ]; then
  echo "======  ERROR ========"
  echo " - Missing Argument... "
  echo "   Please enter the environment file"
  echo " - See Usage"
  echo "======================="
  exit 1
fi

filename="$1"
source $filename

readarray -t EXPORTS < <(printenv | grep -E 'ARM_|TF_')

EXPORTS+=("TF_DATA_DIR=.terraform-${ENVIRONMENT}")

cmd=""
len=${#EXPORTS[@]}
for (( i=0; i<${len}; i++ ));
do
    row=${EXPORTS[$i]}
    row="${row//$'\r'/}" # Remove /r
    row="${row//$'\n'/}" # Remove /n
    row="${row//$/\\$}"  # Escape $

    row="${row/=/=\'}" # Replace = with ='
    row+="'"

    cmd+="export ${row}"
    if (( i < (len - 1) ))
    then
        cmd+=$' && \\ \n'
    fi

done

echo -e "\n\n"
echo $'Run the following commands: \n'
echo "$cmd"