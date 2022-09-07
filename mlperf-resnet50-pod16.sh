#! /bin/bash
if [[ "$#" -gt 1 ||  "$#" == 0 ]]; then
  echo "Usage: $0 IMAGENET_TFRECORD_DIR"
  exit
fi

DATA_DIR=$1
WORKING_DIR=`pwd`
TARGET_POPLAR_SDK_VERSION="2.6.0+1074"
POPLAR_SDK_VERSION="$(python3 -c 'import json; import os; print(json.load(open(os.path.join(os.environ["POPLAR_SDK_ENABLED"], "..", "manifest.json")))["details"]["version"])')"
TRAINING_DIR="${WORKING_DIR}/training_results_v2.0/Graphcore/benchmarks/resnet/implementations/tensorflow"

if [ -z ${POPLAR_SDK_VERSION} ]; then
  echo "Please activate a Poplar SDK."
  exit
else
  if [ ${POPLAR_SDK_VERSION} != ${TARGET_POPLAR_SDK_VERSION} ]; then
    echo "Warning: This script was tested with Poplar SDK ${TARGET_POPLAR_SDK_VERSION}, but you're currently using ${POPLAR_SDK_VERSION}."
  fi
fi

if [ ! -d "${WORKING_DIR}/training_results_v2.0" ]; then
  echo "Cloning the repository mlcommons/training_results_v2.0 ..."
  git clone https://github.com/mlcommons/training_results_v2.0 ${WORKING_DIR}/training_results_v2.0 &> /dev/null
fi

ENV_PATH="${WORKING_DIR}/envs/resnet-tensorflow-${POPLAR_SDK_VERSION}"
if [ ! -d $ENV_PATH ]; then
   echo "Setting up Python3 virtual environment at $ENV_PATH"
   virtualenv -p python3 $ENV_PATH &> /dev/null
   source "$ENV_PATH/bin/activate"

   echo "Installing Tensorflow 1 ..."
   pip install $POPLAR_SDK_ENABLED/../tensorflow-1*amd*.whl &>> "$ENV_PATH/install.log"

   echo "Installing WandB ..."
   pip install wandb &>> $ENV_PATH/install.log

   echo "Installing required packages for Tensorflow 1 CNNs ..."
   cd $TRAINING_DIR
   pip install -r requirements.txt &>> $ENV_PATH/install.log
   cd $WORKING_DIR
else
   echo "Skipping virtualenv setup. $ENV_PATH directory already exists"
   source "$ENV_PATH/bin/activate"
fi

cd $TRAINING_DIR

for ((n=1; n<5; n++)); do
  SEED=$((n << 32));
  TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
  LOG_DIR="${WORKING_DIR}/logs/${TIMESTAMP}"
  mkdir -p ${LOG_DIR}
  OUTPUT_FILE="${WORKING_DIR}/logs/${TIMESTAMP}/output.log"

  echo "Running ResNet50 training with seed ${SEED} ..."
  echo "(To watch the progress, run 'tail -f ${LOG_DIR}/log.txt' on a new terminal)"
  POPLAR_ENGINE_OPTIONS='{"target.hostSyncTimeout":"900"}' \
  POPLAR_RUNTIME_OPTIONS='{"streamCallbacks.maxLookahead":"unlimited"}' \
  poprun \
    --mpi-global-args='--tag-output --allow-run-as-root' \
    --mpi-local-args='-x POPLAR_ENGINE_OPTIONS -x POPLAR_RUNTIME_OPTIONS' \
    --ipus-per-replica 1 --numa-aware 1 \
    --num-instances 8 --num-replicas 16 \
  python -u train.py \
    --config mk2_resnet50_mlperf_pod16_lars \
    --seed ${SEED} \
    --identical-replica-seeding \
    --stochastic-rounding ON \
    --logs-path ${LOG_DIR} \
    --data-dir ${DATA_DIR} \
  &> ${OUTPUT_FILE}
done

echo "Finished benchmarking."
