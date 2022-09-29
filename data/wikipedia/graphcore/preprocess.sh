#! /bin/bash
if [[ "$#" -gt 2 ||  "$#" -lt 2 ]]; then
  echo "Usage: $0 PATH_TO_WIKI_XML OUTPUT_DIRECTORY"
  exit
fi

WIKIDUMP_XML_PATH=$1
DATASET_DIR=$2

if [ ! -f ${WIKIDUMP_XML_PATH} ]; then
  echo "No such file: ${WIKIDUMP_XML_PATH}"
  exit
fi

mkdir -p "${DATASET_DIR}"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
VENV_PATH="${SCRIPT_DIR}/venv"
if [ ! -d ${VENV_PATH} ]; then
  virtualenv -p python3.6 "${VENV_PATH}"
  source ${VENV_PATH}/bin/activate
  pip install wikiextractor nltk torch tensorflow==1.15.2 tfrecord transformers==4.18.0
else
  echo "${VENV_PATH} already exists. Skipping virtual environment setup."
  source ${VENV_PATH}/bin/activate
fi

export PYTHONIOENCODING=utf-8
export LC_ALL=C.UTF-8

echo "Extracting wikidump ..."
EXTRACT_DIR="${DATASET_DIR}/intermediate/extracted"
mkdir -p "${EXTRACT_DIR}"
python -m wikiextractor.WikiExtractor -b 100M --processes 64 -o "${EXTRACT_DIR}" "${WIKIDUMP_XML_PATH}"

echo "Preprocessing extracted data ..."
PREPROCESS_DIR="${DATASET_DIR}/intermediate/preprocessed"
mkdir -p "${PREPROCESS_DIR}"
python "${SCRIPT_DIR}/preprocess.py" --input-file-path "${EXTRACT_DIR}" --output-file-path "${PREPROCESS_DIR}"

echo "Tokenizing with sequence length 128 ..."
SL128_DIR="${DATASET_DIR}/sl128"
mkdir -p "${SL128_DIR}"
python "${SCRIPT_DIR}/tokenize_wikipedia.py" "${PREPROCESS_DIR}" "${SL128_DIR}" --sequence-length 128 --mask-tokens 20

echo "Tokenizing with sequence length 384 ..."
SL384_DIR="${DATASET_DIR}/sl384"
mkdir -p "${SL384_DIR}"
python "${SCRIPT_DIR}/tokenize_wikipedia.py" "${PREPROCESS_DIR}" "${SL384_DIR}" --sequence-length 384 --mask-tokens 56

echo "Tokenizing with sequence length 512 ..."
SL512_DIR="${DATASET_DIR}/sl512"
mkdir -p "${SL512_DIR}"
python "${SCRIPT_DIR}/tokenize_wikipedia.py" "${PREPROCESS_DIR}" "${SL512_DIR}" --sequence-length 512 --mask-tokens 76

cd "${SL128_DIR}"
for f in *.tfrecord; do python -m tfrecord.tools.tfrecord2idx $f `basename $f .tfrecord`.index; done

cd "${SL384_DIR}"
for f in *.tfrecord; do python -m tfrecord.tools.tfrecord2idx $f `basename $f .tfrecord`.index; done

cd "${SL512_DIR}"
for f in *.tfrecord; do python -m tfrecord.tools.tfrecord2idx $f `basename $f .tfrecord`.index; done
