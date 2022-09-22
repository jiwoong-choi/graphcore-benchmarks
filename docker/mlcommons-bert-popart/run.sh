if [[ "$#" -gt 1 ||  "$#" == 0 ]]; then
  echo "Usage: $0 WIKIPEDIA_PACKED512_PATH"
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

  echo "Running BERT-Large pretraining with seed ${SEED} ..."
  echo "(To watch the progress, run 'tail -f ${OUTPUT_FILE}')"
  python -u bert.py \
    --config configs/pod16-closed.json \
    --seed ${SEED} \
    --log-dir ${LOG_DIR} \
    --input-files ${DATA_DIR}/*.tfrecord \
  &> ${OUTPUT_FILE}
done

echo "Finished benchmarking."
