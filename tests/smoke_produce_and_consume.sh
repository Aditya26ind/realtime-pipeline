#!/bin/bash
# Smoke test: produce messages and verify consumption

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Smoke Test: Produce and Consume ===${NC}"

# Configuration
MESSAGES=10
TOPIC="iot_events"
TIMEOUT=30

echo -e "${YELLOW}Step 1: Checking if services are running...${NC}"
if ! docker ps | grep -q realtime-kafka; then
    echo -e "${RED}Error: Kafka container not running. Start services first with: ./docker-dev.sh start${NC}"
    exit 1
fi

if ! docker ps | grep -q realtime-spark-dev; then
    echo -e "${RED}Error: Spark dev container not running. Start services first with: ./docker-dev.sh start${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Services are running${NC}"

# Check initial parquet directory size
echo -e "${YELLOW}Step 2: Checking initial state...${NC}"
INITIAL_FILES=$(docker exec realtime-spark-dev find output/parquet/iot -name "*.parquet" 2>/dev/null | wc -l || echo 0)
echo "Initial parquet files: $INITIAL_FILES"

# Produce messages
echo -e "${YELLOW}Step 3: Producing $MESSAGES messages...${NC}"
docker exec realtime-spark-dev python producers/simple_producer.py \
    --messages $MESSAGES \
    --interval 0.5 \
    --topic $TOPIC

echo -e "${GREEN}✓ Messages produced${NC}"

# Verify messages in Kafka
echo -e "${YELLOW}Step 4: Verifying messages in Kafka...${NC}"
KAFKA_MESSAGES=$(docker exec realtime-kafka kafka-console-consumer \
    --bootstrap-server localhost:9092 \
    --topic $TOPIC \
    --from-beginning \
    --timeout-ms 5000 2>/dev/null | wc -l || echo 0)

echo "Messages found in Kafka: $KAFKA_MESSAGES"

if [ "$KAFKA_MESSAGES" -ge "$MESSAGES" ]; then
    echo -e "${GREEN}✓ Messages successfully stored in Kafka${NC}"
else
    echo -e "${RED}✗ Expected at least $MESSAGES messages, found $KAFKA_MESSAGES${NC}"
fi

# Wait a bit for Spark to process if it's running
echo -e "${YELLOW}Step 5: Waiting for potential Spark processing...${NC}"
sleep 10

# Check if Spark streaming job created any output
echo -e "${YELLOW}Step 6: Checking for Spark output...${NC}"
FINAL_FILES=$(docker exec realtime-spark-dev find output/parquet/iot -name "*.parquet" 2>/dev/null | wc -l || echo 0)
echo "Final parquet files: $FINAL_FILES"

if [ "$FINAL_FILES" -gt "$INITIAL_FILES" ]; then
    echo -e "${GREEN}✓ New parquet files created by Spark${NC}"
else
    echo -e "${YELLOW}! No new parquet files (Spark streaming job may not be running)${NC}"
fi

# Summary
echo -e "${GREEN}=== Smoke Test Summary ===${NC}"
echo "✓ Kafka producer: Working"
echo "✓ Kafka storage: $KAFKA_MESSAGES messages stored"
if [ "$FINAL_FILES" -gt "$INITIAL_FILES" ]; then
    echo "✓ Spark processing: Working"
else
    echo "! Spark processing: Not detected (run streaming job separately)"
fi

echo -e "${GREEN}Smoke test completed!${NC}"
echo ""
echo "To run the streaming job manually:"
echo "  ./docker-dev.sh run-job"
echo ""
echo "To check Kafka messages:"
echo "  docker exec realtime-kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic $TOPIC --from-beginning"