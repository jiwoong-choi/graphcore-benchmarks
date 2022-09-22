#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "${SCRIPT_DIR}"
VENV_PATH="${SCRIPT_DIR}/venv"

if [ ! -d ${VENV_PATH} ]; then
  virtualenv -p python3.6 ${VENV_PATH}
  source ${VENV_PATH}/bin/activate
  pip install gdown
else
  echo "${VENV_PATH} already exists. Skipping virtual environment setup."
  source ${VENV_PATH}/bin/activate
fi

function download_from_gdrive_link () {
  local FILE_PATH=$1
  local URL=$2
  local MD5HASH_TRG=$3
  if [ ! -f ${FILE_PATH} ]; then
    gdown -O ${FILE_PATH} ${URL}
  else
    local MD5HASH_SRC="$(md5sum ${BZ2_PATH} | awk '{print $1}')"
    if [[ ${MD5HASH_SRC} == ${MD5HASH_TRG} ]]; then
      echo "${FILE_PATH} is already downloaded and verified"
    else
      echo "${FILE_PATH} found, but it is complete"
      gdown -c -O ${FILE_PATH} ${URL}
    fi
  fi
}


rm -rf results
download_from_gdrive_link results.zip https://drive.google.com/uc?id=1dy_Jt3s6CYy6SqAJeIveI1P2msSNlhBH ed72bada4134bfa2e91036746e45e551
unzip results.zip
mv results4 results
