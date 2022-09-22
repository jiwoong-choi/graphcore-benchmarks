#! /bin/bash
if [[ "$#" -gt 1 ||  "$#" == 0 ]]; then
  echo "Usage: $0 DIRECTORY_TO_DOWNLOAD_IMAGENET"
  exit
fi

DATASET_DIR=$1
if [ ! -d ${DATASET_DIR} ]; then
  echo "Error: ${DATASET_DIR}: no such directory"
  exit
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
TRAINING_FILE="${DATASET_DIR}/ILSVRC2012_img_train.tar"
VALIDATION_FILE="${DATASET_DIR}/ILSVRC2012_img_val.tar"
TRAIN_DIR="${DATASET_DIR}/train"
VAL_DIR="${DATASET_DIR}/val"

function download-from-link () {
  local FILE_PATH=$1
  local URL=$2
  local EXPECTED_FILE_SIZE=$3
  if [ ! -f ${FILE_PATH} ]; then
    echo "Downloading ${FILE_PATH} ..."
    wget -O ${FILE_PATH} ${URL}
  else
    local FILE_SIZE="$(ls -l ${FILE_PATH} | awk '{print $5}')"
    if [[ ${FILE_SIZE} == ${EXPECTED_FILE_SIZE} ]]; then
      echo "${FILE_PATH} already downloaded."
    else
      echo "${FILE_PATH} is found, but not complete. (expected size was ${EXPECTED_FILE_SIZE}, but got ${FILE_SIZE})"
      echo "Continuing to download ${FILE_PATH} ..."
      wget -cO ${FILE_PATH} ${URL}
    fi
  fi
}

function unpack-training-file () {
  mkdir -p ${TRAIN_DIR}
  cd ${TRAIN_DIR}
  download-from-link ${TRAINING_FILE} "https://image-net.org/data/ILSVRC/2012/ILSVRC2012_img_train.tar" 147897477120
  echo "Unpacking ${TRAINING_FILE} ..."
  tar -xvf "${TRAINING_FILE}" &> /dev/null
  ls *.tar | while read NAME; do mkdir -p "${NAME%.tar}"; cd "${NAME%.tar}"; echo "Unpacking ${NAME} ..."; tar -xvf ../$NAME &> /dev/null; cd ..; rm $NAME; done
  cd ${DATASET_DIR}
  rm ${TRAINING_FILE}
}

function unpack-validation-file () {
  mkdir -p ${VAL_DIR}
  cd ${VAL_DIR}
  download-from-link ${VALIDATION_FILE} "https://image-net.org/data/ILSVRC/2012/ILSVRC2012_img_val.tar" 6744924160
  echo "Unpacking ${VALIDATION_FILE} ..."
  tar -xvf "${VALIDATION_FILE}" &> /dev/null
  wget -qO- https://raw.githubusercontent.com/soumith/imagenetloader.torch/master/valprep.sh | bash
  cd ${DATASET_DIR}
  rm ${VALIDATION_FILE}
}

if [ ! -d ${TRAIN_DIR} ]; then
  unpack-training-file
else
  TRAIN_DIR_SIZE="$(du --max-depth 0 ${TRAIN_DIR} | awk '{print $1}')"
  if [[ ${TRAIN_DIR_SIZE} -eq 146087396 ]]; then
    echo "${TRAINING_FILE} already unpacked."
  else
    echo "${TRAIN_DIR} is found, but not complete. (expected size was 146087396, but got ${TRAIN_DIR_SIZE})"
    rm -rf ${TRAIN_DIR}
    unpack-training-file
  fi
fi

if [ ! -d ${VAL_DIR} ]; then
  unpack-validation-file
else
  VAL_DIR_SIZE="$(du --max-depth 0 ${VAL_DIR} | awk '{print $1}')"
  if [[ ${VAL_DIR_SIZE} -eq 6655292 ]]; then
    echo "${VALIDATION_FILE} already unpacked."
  else
    echo "${VAL_DIR} is found, but not complete. (expected size was 6655292, but got ${VAL_DIR_SIZE})"
    rm -rf ${VAL_DIR}
    unpack-validation-file
  fi
fi

cd ${SCRIPT_DIR}
VENV_PATH="${SCRIPT_DIR}/venv"
BBOX_INFO_PATH="${DATASET_DIR}/imagenet_2012_bounding_boxes.csv"
TFRECORD_DIR="${DATASET_DIR}/tfrecord"
download-from-link ${BBOX_INFO_PATH} https://repository.prace-ri.eu/git/Data-Analytics/Benchmarks/-/raw/bfea8c2c69078a98c35a6e774809e7d9cc807874/ImageNetUseCaseV2/Dataset/Metadata/imagenet_2012_bounding_boxes.csv?inline=false 29709928
if [ ! -d ${VENV_PATH} ]; then
  virtualenv -p python3.6 ${VENV_PATH}
  source ${VENV_PATH}/bin/activate
  pip install tensorflow==1.15.2
else
  echo "${VENV_PATH} already exists. Skipping virtual environment setup."
  source ${VENV_PATH}/bin/activate
fi
mkdir -p ${TFRECORD_DIR}
python imagenet-to-tfrecord.py \
  --bounding_box_file ${BBOX_INFO_PATH} \
  --imagenet_metadata_file imagenet_metadata.txt \
  --labels_file imagenet_lsvrc_2015_synsets.txt \
  --output_directory ${TFRECORD_DIR} \
  --train_directory ${TRAIN_DIR} \
  --validation_directory ${VAL_DIR}
