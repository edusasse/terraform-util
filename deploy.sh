#!/bin/bash

show_help() {
    echo "Usage: $(basename $0) [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -dev                    Set environment to 'dev'"
    echo "  -int                    Set environment to 'int'"
    echo "  -prod                   Set environment to 'prod'"
    echo "  -visual                 Generate Terraform plan and output it in JSON format"
    echo "  -destroy                Destroy resources"
    echo "  -clean-state            Remove Terraform state files and directories"
    echo "  -tfstate [plan|apply]   Initialize Terraform and perform plan or apply"
    echo "  -auto-approve           Automatically approve Terraform apply"
    echo ""
    echo "Environment variables can be set using environment files in the format:"
    echo "  .terraform/.terraform-dev-env.sh"
    echo "  .terraform/.terraform-int-env.sh"
    echo "  .terraform/.terraform-prod-env.sh"
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


ENV="dev" # Default environment is 'dev'
if [[ "${ARGS}" == *-dev* ]]; then
    ENV="dev"
fi
if [[ "${ARGS}" == *-int* ]]; then
    ENV="int"
fi
if [[ "${ARGS}" == *-prod* ]]; then
    ENV="prod"
fi
export TF_DATA_DIR=".terraform/.terraform-${ENV}"

setEnvFileName=$(find ${CURRENT_DIR} -type f -name "*${ENV}-env.sh")
echo -e "--> [INFO] Set environment variables from file: ${setEnvFileName}\n"
if [ -n "$setEnvFileName" ]; then
    source $setEnvFileName
fi

echo -e "--> [INFO] Deploy using following environment variables:\n" 
for var in $(printenv | grep -E 'ARM_|TF_'); do
  echo "   $var"
done



if [[ "${ARGS}" == *visual* ]]; then
    
    cmd="terraform plan -out=plan.out && terraform show -json plan.out > plan.json"

elif [[ "${ARGS}" == *destroy* ]]; then
    
    cmd="terraform destroy"

elif [[ "${ARGS}" == *-clean-state* ]]; then
    cmd="rm -rf .terraform*"
    echo "${cmd}"
    bash -c "$cmd"
    exit $?

elif [[ "${ARGS}" == *-tfstate* ]]; then

    cmd="terraform init -upgrade -backend-config=${ENV}.tfbackend"

    if [[ "${ARGS}" == *plan* ]]; then
        cmd="${cmd} && terraform plan "
    fi

    if [[ "${ARGS}" == *apply* ]]; then
        cmd="${cmd} && terraform apply "
        if [[ "${ARGS}" == *auto-approve* ]]; then
            cmd="${cmd} -auto-approve"
        fi
    fi

else    

    cmd="terraform init -upgrade -backend-config=./environment/${ENV}/${ENV}.tfbackend"

    if [[ "${ARGS}" == *plan* ]]; then
        cmd="${cmd} && terraform plan "
    fi

    if [[ "${ARGS}" == *apply* ]]; then
        cmd="${cmd} && terraform apply "
        if [[ "${ARGS}" == *auto-approve* ]]; then
            cmd="${cmd} -auto-approve"
        fi
    fi
fi

echo -e "\n--> [CMD] ${cmd}\n"
bash -c "$cmd 2>&1 | tee init_${ENV}.log"

if [[ "${ARGS}" == *visual* ]]; then
    echo "=================================================="
    echo "Check https://hieven.github.io/terraform-visual/"
    echo "=================================================="
fi