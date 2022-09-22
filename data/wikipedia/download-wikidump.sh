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

mkdir -p wiki

download_from_gdrive_link wiki/bert_config.json https://drive.google.com/uc?id=1fbGClQMi2CoMv7fwrwTC5YYPooQBdcFW 7f59165e21b7d566db610ff6756c926b
download_from_gdrive_link wiki/License.txt https://drive.google.com/uc?id=1SYfj3zsFPvXwo4nUVkAS54JVczBFLCWI 4550b87b0ea99302e44c84f6bed9aa97
download_from_gdrive_link wiki/vocab.txt https://drive.google.com/uc?id=1USK108J6hMM_d27xCHi738qBL8_BT1u1 64800d5d8528ce344256daf115d4965e

BZ2_PATH="wiki/wikidump.xml.bz2"
XML_PATH="wiki/wikidump.xml"

if [ -f ${XML_PATH} ]; then
  MD5HASH_SRC="$(md5sum ${XML_PATH} | awk '{print $1}')"
  MD5HASH_TRG="1021bd606cba24ffc4b93239f5a09c02"\

  if [[ ${MD5HASH_SRC} == ${MD5HASH_TRG} ]]; then
    echo "${XML_PATH} found and verified"
  else
    echo "${XML_PATH} found, but it is complete."
    download_from_gdrive_link ${BZ2_PATH} https://drive.google.com/uc?id=18K1rrNJ_0lSR9bsLaoP3PkQeSFO-9LE7 00d47075e0f583fb7c0791fac1c57cb3
    echo "Uncompressing ${BZ2_PATH} ..."
    bzip2 -d ${BZ2_PATH}
  fi
else
  echo "${XML_PATH} not found"
  download_from_gdrive_link ${BZ2_PATH} https://drive.google.com/uc?id=18K1rrNJ_0lSR9bsLaoP3PkQeSFO-9LE7 00d47075e0f583fb7c0791fac1c57cb3
  echo "Uncompressing ${BZ2_PATH} ..."
  bzip2 -d ${BZ2_PATH}
fi


mkdir -p tf1_ckpt

cd tf1_ckpt

gdown -c https://drive.google.com/uc?id=1chiTBljF0Eh1U5pKs6ureVHgSbtU8OG_

gdown -c https://drive.google.com/uc?id=1Q47V3K3jFRkbJ2zGCrKkKk-n0fvMZsa0

gdown -c https://drive.google.com/uc?id=1vAcVmXSLsLeQ1q7gvHnQUSth5W_f_pwv

cd ..

# Download TF-2 checkpoints
mkdir -p tf2_ckpt

cd tf2_ckpt

gdown -c https://drive.google.com/uc?id=1pJhVkACK3p_7Uc-1pAzRaOXodNeeHZ7F

gdown -c https://drive.google.com/uc?id=1oVBgtSxkXC9rH2SXJv85RXR9-WrMPy-Q
