#!/usr/bin/env python3
"""
Simple Kafka producer for IoT events.
Generates sample temperature data and sends to 'iot_events' topic.
"""

import json
import time
import random
from datetime import datetime
from kafka import KafkaProducer
import uuid
import argparse
import os

def create_producer():
    """Create Kafka producer with appropriate configuration."""
    # Check if running in Docker
    if os.getenv('SPARK_MODE'):
        bootstrap_servers = ['kafka:29092']
    else:
        bootstrap_servers = ['localhost:9092']
    
    return KafkaProducer(
        bootstrap_servers=bootstrap_servers,
        value_serializer=lambda v: json.dumps(v).encode('utf-8'),
        key_serializer=lambda k: k.encode('utf-8') if k else None,
        retries=5,
        retry_backoff_ms=100,
        request_timeout_ms=30000
    )

def generate_iot_event(device_id=None):
    """Generate a sample IoT temperature event."""
    if device_id is None:
        device_id = f"device_{random.randint(1, 10)}"
    
    return {
        "event_id": str(uuid.uuid4()),
        "device_id": device_id,
        "ts": datetime.now().isoformat(),
        "temperature": round(random.uniform(18.0, 35.0), 2)
    }

def main():
    parser = argparse.ArgumentParser(description='IoT Events Producer')
    parser.add_argument('--messages', type=int, default=10, help='Number of messages to send')
    parser.add_argument('--interval', type=float, default=1.0, help='Interval between messages in seconds')
    parser.add_argument('--topic', default='iot_events', help='Kafka topic name')
    args = parser.parse_args()

    # Create producer
    producer = create_producer()
    
    print(f"Starting producer...")
    print(f"Sending {args.messages} messages to topic '{args.topic}' with {args.interval}s interval")
    
    try:
        for i in range(args.messages):
            # Generate event
            event = generate_iot_event()
            
            # Send to Kafka
            future = producer.send(
                args.topic,
                key=event['device_id'],
                value=event
            )
            
            # Wait for send to complete
            record_metadata = future.get(timeout=10)
            
            print(f"Message {i+1}/{args.messages} sent: {event['device_id']} - {event['temperature']}°C")
            print(f"  Topic: {record_metadata.topic}, Partition: {record_metadata.partition}, Offset: {record_metadata.offset}")
            
            if i < args.messages - 1:  # Don't sleep after the last message
                time.sleep(args.interval)
                
    except KeyboardInterrupt:
        print("\nProducer interrupted by user")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        producer.close()
        print("Producer closed")

if __name__ == "__main__":
    main()