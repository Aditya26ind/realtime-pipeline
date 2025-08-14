#!/usr/bin/env python3
"""
Spark Structured Streaming job for real-time data pipeline.
Reads from Kafka topic 'iot_events' and writes to console and Parquet files.
"""

from pyspark.sql import SparkSession
from pyspark.sql.functions import from_json, col, to_timestamp
from pyspark.sql.types import StructType, StringType, DoubleType
import os

def create_spark_session():
    """Create Spark session with necessary configurations for Kafka integration."""
    return (SparkSession.builder
            .appName("realtime-pipeline-streaming")
            .config("spark.sql.adaptive.enabled", "true")
            .config("spark.sql.adaptive.coalescePartitions.enabled", "true")
            .config("spark.jars.packages", "org.apache.spark:spark-sql-kafka-0-10_2.12:3.2.0")
            .getOrCreate())

def get_kafka_config():
    """Get Kafka configuration based on environment."""
    # Check if running in Docker
    if os.getenv('SPARK_MODE'):
        return "kafka:29092"
    else:
        return "localhost:9092"

def main():
    # Create Spark session
    spark = create_spark_session()
    spark.sparkContext.setLogLevel("WARN")
    
    # Define schema for IoT events
    schema = (StructType()
              .add("event_id", StringType())
              .add("device_id", StringType()) 
              .add("ts", StringType())
              .add("temperature", DoubleType()))

    # Get Kafka bootstrap servers
    kafka_servers = get_kafka_config()
    print(f"Connecting to Kafka at: {kafka_servers}")

    # Read from Kafka
    raw_stream = (spark.readStream
                  .format("kafka")
                  .option("kafka.bootstrap.servers", kafka_servers)
                  .option("subscribe", "iot_events")
                  .option("startingOffsets", "latest")
                  .option("failOnDataLoss", "false")
                  .load())

    # Parse JSON and extract data
    parsed_stream = (raw_stream
                     .selectExpr("CAST(value AS STRING) as json_str")
                     .select(from_json(col("json_str"), schema).alias("data"))
                     .select("data.*")
                     .withColumn("ts", to_timestamp(col("ts"))))

    # Add watermark and deduplicate
    clean_stream = (parsed_stream
                    .withWatermark("ts", "2 minutes")
                    .dropDuplicates(["event_id"]))

    # Write to console
    console_query = (clean_stream.writeStream
                     .format("console")
                     .option("truncate", False)
                     .option("numRows", 20)
                     .outputMode("append")
                     .start())

    # Write to Parquet with checkpointing
    parquet_query = (clean_stream.writeStream
                     .format("parquet")
                     .option("path", "output/parquet/iot")
                     .option("checkpointLocation", "checkpoints/iot")
                     .outputMode("append")
                     .trigger(processingTime="10 seconds")
                     .start())

    print("Streaming queries started...")
    print("Console output query:", console_query.id)
    print("Parquet output query:", parquet_query.id)
    print("Spark UI available at: http://localhost:4040")
    
    try:
        # Wait for termination
        console_query.awaitTermination()
        parquet_query.awaitTermination()
    except KeyboardInterrupt:
        print("Stopping streaming queries...")
        console_query.stop()
        parquet_query.stop()
        spark.stop()

if __name__ == "__main__":
    main()