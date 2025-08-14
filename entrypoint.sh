#!/usr/bin/env bash
set -euo pipefail

# Print effective configuration
echo "Starting Spark Streaming Job with configuration:"
echo "  SPARK_MASTER_URL=${SPARK_MASTER_URL}"
echo "  KAFKA_BOOTSTRAP_SERVERS=${KAFKA_BOOTSTRAP_SERVERS}"
echo "  KAFKA_TOPIC=${KAFKA_TOPIC}"
echo "  OUTPUT_PATH=${OUTPUT_PATH}"
echo "  CHECKPOINT_PATH=${CHECKPOINT_PATH}"

# Submit job
exec spark-submit \
  --master "${SPARK_MASTER_URL}" \
  --conf spark.sql.adaptive.enabled=true \
  --conf spark.sql.streaming.checkpointLocation="${CHECKPOINT_PATH}" \
  ${SPARK_SUBMIT_ARGS} \
  spark_jobs/streaming_job.py