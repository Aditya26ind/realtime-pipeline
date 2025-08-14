#!/bin/bash
# Development helper script for Docker-based Spark development

set -e

COMPOSE_FILE="infra/docker-compose.yml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  start     - Build and start all services (Kafka, Zookeeper, Spark, etc.)"
    echo "  stop      - Stop all services"
    echo "  restart   - Restart all services"
    echo "  rebuild   - Rebuild and restart services"
    echo "  logs      - Show logs for all services"
    echo "  spark-sh  - Open shell in Spark development container"
    echo "  run-job   - Run the streaming job in Docker"
    echo "  produce   - Run the simple producer (10 messages)"
    echo "  status    - Show status of all services"
    echo "  clean     - Stop services and remove volumes"
    echo ""
    echo "Web UIs:"
    echo "  Kafka UI:      http://localhost:8080"
    echo "  Spark Master:  http://localhost:8083"
    echo "  Spark Worker:  http://localhost:8082"
    echo "  Spark App UI:  http://localhost:4040 (when job running)"
}

start_services() {
    echo -e "${GREEN}Building and starting all services...${NC}"
    docker-compose -f $COMPOSE_FILE up -d --build
    echo -e "${GREEN}Services started!${NC}"
    echo ""
    echo "Web UIs available at:"
    echo "  Kafka UI:      http://localhost:8080"
    echo "  Spark Master:  http://localhost:8083"
    echo "  Spark Worker:  http://localhost:8082"
    echo "  Spark App UI:  http://localhost:4040 (when job running)"
}

stop_services() {
    echo -e "${YELLOW}Stopping all services...${NC}"
    docker-compose -f $COMPOSE_FILE down
    echo -e "${GREEN}Services stopped!${NC}"
}

restart_services() {
    stop_services
    start_services
}

rebuild_services() {
    echo -e "${YELLOW}Rebuilding and restarting all services...${NC}"
    docker-compose -f $COMPOSE_FILE down
    docker-compose -f $COMPOSE_FILE up -d --build --force-recreate
    echo -e "${GREEN}Services rebuilt and started!${NC}"
}

show_logs() {
    docker-compose -f $COMPOSE_FILE logs -f
}

spark_shell() {
    echo -e "${GREEN}Opening shell in Spark development container...${NC}"
    echo "Use 'exit' to return to host shell"
    docker exec -it realtime-spark-dev bash
}

run_streaming_job() {
    echo -e "${GREEN}Running Spark streaming job...${NC}"
    echo "Note: Code changes will be automatically reflected without rebuilding!"
    docker exec -it realtime-spark-dev spark-submit \
        --master spark://spark-master:7077 \
        spark_jobs/streaming_job.py
}

run_producer() {
    echo -e "${GREEN}Running simple producer (10 messages)...${NC}"
    docker exec -it realtime-spark-dev python producers/simple_producer.py --messages 10 --interval 1
}

show_status() {
    echo -e "${GREEN}Service Status:${NC}"
    docker-compose -f $COMPOSE_FILE ps
}

clean_all() {
    echo -e "${RED}Stopping services and removing volumes...${NC}"
    docker-compose -f $COMPOSE_FILE down -v
    echo -e "${GREEN}Cleanup complete!${NC}"
}

# Main script logic
case "$1" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    rebuild)
        rebuild_services
        ;;
    logs)
        show_logs
        ;;
    spark-sh)
        spark_shell
        ;;
    run-job)
        run_streaming_job
        ;;
    produce)
        run_producer
        ;;
    status)
        show_status
        ;;
    clean)
        clean_all
        ;;
    *)
        print_usage
        exit 1
        ;;
esac