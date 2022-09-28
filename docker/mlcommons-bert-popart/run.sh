if [[ "$#" -gt 2 ||  "$#" -lt 2 ]]; then
  echo "Usage: $0 TRAINING_DATA_DIR VALIDATION_DATA_DIR"
  exit
fi

TRAINING_DATA_DIR=$1
VALIDATION_DATA_DIR=$2
WORKING_DIR=`pwd`
source /venv/bin/activate || exit

for ((n=1; n<5; n++)); do
  SEED=$((n << 16));
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
    --input-files ${TRAINING_DATA_DIR}/* \
    --on-the-spot-validation-files ${VALIDATION_DATA_DIR}/* \
  &> ${OUTPUT_FILE}
done

echo "Finished benchmarking."
