if [[ "$#" -gt 1 ||  "$#" == 0 ]]; then
  echo "Usage: $0 IMAGENET_TFRECORD_DIR"
  exit
fi

DATA_DIR=$1
WORKING_DIR=`pwd`
source /venv/bin/activate || exit

for ((n=1; n<5; n++)); do
  SEED=$((n << 32));
  TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
  LOG_DIR="${WORKING_DIR}/logs/${TIMESTAMP}"
  mkdir -p ${LOG_DIR}
  OUTPUT_FILE="${LOG_DIR}/output.log"

  echo "Running ResNet50 training with seed ${SEED} ..."
  echo "(To watch the progress, run 'tail -f ${LOG_DIR}/log.txt' or 'tail -f ${OUTPUT_FILE}')"
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
