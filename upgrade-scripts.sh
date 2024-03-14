#!/bin/bash
ARGS=$*
CURRENT_DIR=$(dirname $(realpath $0))

echo "#########################################"
echo "#"
echo "#  CURRENT_DIR.......: ${CURRENT_DIR}"
echo "#  ARGS..............: ${ARGS}"
echo "#"
echo "#########################################"
echo ""

GITHUB_REPO="https://github.com/edusasse/terraform-util.git"
BRANCH="main"

# The name of the scripts to be downloaded from the repository
UPGRADE_SCRIPT_NAME="upgrade-scripts.sh"
DEPLOY_SCRIPT_NAME="deploy.sh"
SET_ENV_SCRIPT_NAME="set-env.sh"
LOG_STREAM_SCRIPT_NAME="log-stream.sh"

show_help() {
    echo "Usage: $(basename $0) [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -enc                    Encrypt Environment Files"
    echo "  -dec                    Decrypt Environment Files"
}

download_script() {
	theScript=$1
    echo "Cloning repository from ${GITHUB_REPO} (branch: ${BRANCH})"
    git clone --branch ${BRANCH} --single-branch ${GITHUB_REPO} ${CURRENT_DIR}/temp_script_download
    cp "${CURRENT_DIR}/temp_script_download/${theScript}" ${CURRENT_DIR}
    rm -rf ${CURRENT_DIR}/temp_script_download
    chmod +x ${CURRENT_DIR}/${theScript}
    echo "==================== ${theScript} ====================="
    echo "Script downloaded successfully: ${theScript}"
    echo "Run \"./${theScript} -h\" for more information"
    echo "=================================================="
}

encryptDecrypt() {
    theOperation=$1
    thePath=$2
    
    echo -n "Enter master password: "
    read -s master_password
    echo ""
    echo ""

    key=$(echo -n "${master_password}" | openssl dgst -sha256 | awk '{print $2}')
    iv="${key:0:32}" # Extract the first 32 characters
    
    encFilePath="${thePath}/enc/"
    if [[ "${theOperation}" == '-enc' ]]; then
        patterns=("*-dev-env.sh" "*-int-env.sh" "*-prod-env.sh")

        for pattern in "${patterns[@]}"; do
            for file in "${thePath}/"${pattern}; do
                if [ -f "$file" ]; then  # Check if it's a regular file
                    mkdir -p "${thePath}/enc/"
                    encFile="${thePath}/enc/"$(basename "${file%.*}.enc")
                    echo "[INFO] Encrypt: ${file} to ${encFile}" 

                    # Encrypt and Transform Plain Text
                    openssl enc -v -aes-256-cbc -salt -in "$file" -iv "${iv}" -K "${key}" | xxd -plain > "${encFile}"
                fi
            done
        done
    fi

    if [[ "${theOperation}" == '-dec' ]]; then
        patterns=("*-dev-env.enc" "*-int-env.enc" "*-prod-env.enc")

        for pattern in "${patterns[@]}"; do
            for file in "${encFilePath}/"${pattern}; do
                if [ -f "$file" ]; then  # Check if it's a regular file
                    decFile="${thePath}/"$(basename "${file%.*}.sh")
                    echo "[INFO] Decrypt: ${file} to ${decFile}" 

                    # Revert PlainText conversion and Decrypt
                    xxd -plain -revert "${file}" | openssl enc -v -d -aes-256-cbc -salt -out "${decFile}" -iv "${iv}" -K "${key}"
                fi
            done
        done
    fi
}

if [[ "${ARGS}" == *-h* || "${ARGS}" == *--help* ]]; then
    show_help
    exit 0
elif [[ "${ARGS}" == *-enc* ]]; then
    encryptDecrypt "-enc" "${CURRENT_DIR}"
    exit 0
elif [[ "${ARGS}" == *-dec* ]]; then
    encryptDecrypt "-dec" "${CURRENT_DIR}"
    exit 0
else 
    # Download each script from the repository
    download_script "${UPGRADE_SCRIPT_NAME}"
    download_script "${DEPLOY_SCRIPT_NAME}"
    download_script "${SET_ENV_SCRIPT_NAME}"
    download_script "${LOG_STREAM_SCRIPT_NAME}"
fi