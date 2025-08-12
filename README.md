# Real-time Data Pipeline

End-to-end real-time data pipeline: Kafka → Spark → Snowflake

**Dataset**: IoT sensor events (temperature, humidity, pressure, and device status data)

## Project Overview

This project implements a complete real-time data processing pipeline that ingests IoT sensor data through Apache Kafka, processes it using Apache Spark Streaming, and stores the results in Snowflake for analytics and reporting.

## Architecture

```
IoT Devices → Kafka → Spark Streaming → Snowflake
```

## Directory Structure

- `infra/` - Infrastructure as Code (Docker, Kubernetes, Terraform)
- `producers/` - Kafka data producers and simulators
- `spark_jobs/` - Spark streaming applications and batch jobs
- `tests/` - Unit and integration tests
- `docs/` - Documentation and architecture diagrams
- `notebooks/` - Jupyter notebooks for analysis and prototyping

## Getting Started

*Coming soon...*