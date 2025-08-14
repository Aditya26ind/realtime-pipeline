# 🚀 Real-time Data Pipeline

A complete streaming data pipeline using **Kafka** and **Spark** for real-time IoT data processing, built for pure Docker development.

## 🎯 What This Pipeline Does

```
📱 IoT Sensors → 🏭 Producer → 📊 Kafka → ⚡ PySpark → 💾 Parquet Files
```

- **Producers**: Simulate IoT temperature sensors sending data
- **Kafka**: Reliable message streaming and buffering
- **PySpark**: Real-time data processing with filtering and aggregations
- **Output**: Console logs + Parquet files with checkpointing

## ⚡ Quick Start (Pure Docker - No Local Setup Required)

### 1. Start All Services
```bash
./docker-dev.sh start
```

### 2. Run the Streaming Job
```bash
./docker-dev.sh run-job
```

### 3. Send Test Data
```bash
./docker-dev.sh produce
```

### 4. Monitor via Web UIs
- **Kafka UI**: http://localhost:8080
- **Spark Master**: http://localhost:8083  
- **Spark Worker**: http://localhost:8082
- **Spark Application**: http://localhost:4040 (when job running)

## 🛠️ Development Commands

| Command | Description |
|---------|-------------|
| `./docker-dev.sh start` | Build and start all services |
| `./docker-dev.sh run-job` | Run Spark streaming job |
| `./docker-dev.sh produce` | Send 10 test messages |
| `./docker-dev.sh spark-sh` | Open shell in dev container |
| `./docker-dev.sh logs` | View all service logs |
| `./docker-dev.sh rebuild` | Rebuild containers |
| `./docker-dev.sh clean` | Stop and remove all data |

## 📁 Project Structure

```
realtime-pipeline/
├── docker-dev.sh              # Development helper script
├── Dockerfile.dev             # Custom dev environment
├── requirements.txt           # Python dependencies
├── infra/
│   └── docker-compose.yml     # All services definition
├── spark_jobs/
│   └── streaming_job.py       # Main Spark streaming job
├── producers/
│   └── simple_producer.py     # Kafka producer for testing
├── tests/
│   └── smoke_produce_and_consume.sh  # Automated testing
├── output/                    # Parquet files (auto-created)
│   └── parquet/iot/
└── checkpoints/               # Spark checkpoints (auto-created)
    └── iot/
```

## 🔧 Architecture Components

### 🏭 **Producer** (`producers/simple_producer.py`)
**What it does**: Creates and sends IoT sensor data to Kafka

**Current (Development)**:
```python
# Fake sensor data
{
    "event_id": "abc123",
    "device_id": "sensor_1", 
    "temperature": 23.5,
    "timestamp": "2024-01-15T10:30:00"
}
```

**Replace with Real Data**:
```python
# Arduino/IoT sensors
temperature = arduino.read_sensor()

# Weather APIs  
temperature = requests.get('api.weather.com').json()['temp']

# Database changes
temperature = db.sensors.latest_reading()

# MQTT devices
def on_mqtt_message(client, userdata, message):
    data = json.loads(message.payload.decode())
    producer.send('iot_events', data)
```

### 📊 **Kafka** (Message Highway)
**What it does**: Stores and routes messages between systems

**Benefits**:
- **Reliability**: Messages persist until processed
- **Scalability**: Handles millions of messages/second  
- **Decoupling**: Producer and consumer work independently
- **Multiple Consumers**: Same data can feed multiple systems

**Topic**: `iot_events` (auto-created)

### ⚡ **PySpark** (`spark_jobs/streaming_job.py`)
**What it does**: Real-time stream processing with advanced capabilities

**Features**:
- **Real-time Processing**: Processes data as it arrives
- **Filtering**: `df.filter(col("temperature") > 25)`
- **Watermarking**: Handles late-arriving data  
- **Deduplication**: Removes duplicate events
- **Checkpointing**: Fault tolerance and recovery
- **Multiple Outputs**: Console + Parquet files

## 🔄 Live Development Features

### ✅ **No Local Dependencies Required**
- Everything runs in Docker containers
- No need to install Spark, Kafka, or Java locally

### ✅ **Live Code Reloading**  
- Code changes automatically reflected in containers
- No need to rebuild containers for code changes
- Volume mounts sync your local files to containers

### ✅ **Persistent Data**
- Output files and checkpoints survive container restarts
- Kafka data persisted across sessions

### ✅ **Complete Observability**
- Web UIs for monitoring all components
- Logs accessible via `./docker-dev.sh logs`

## 🧪 Testing

### Automated Smoke Test
```bash
./tests/smoke_produce_and_consume.sh
```

### Manual Testing
```bash
# 1. Start everything
./docker-dev.sh start

# 2. Run streaming job (Terminal 1)
./docker-dev.sh run-job

# 3. Send test data (Terminal 2)  
./docker-dev.sh produce

# 4. Check output files
./docker-dev.sh spark-sh
ls -la output/parquet/iot/
ls -la checkpoints/iot/
```

### Monitoring Messages
```bash
# View Kafka messages
docker exec realtime-kafka kafka-console-consumer \
    --bootstrap-server localhost:9092 \
    --topic iot_events \
    --from-beginning
```

## 🌍 Real-World Usage

### IoT Temperature Monitoring
Replace the fake producer with real sensor data:

```python
# producers/real_iot_producer.py
import paho.mqtt.client as mqtt

def on_connect(client, userdata, flags, rc):
    client.subscribe("sensors/+/temperature")

def on_message(client, userdata, msg):
    sensor_data = {
        "device_id": msg.topic.split('/')[1],
        "temperature": float(msg.payload.decode()),
        "timestamp": datetime.now().isoformat()
    }
    kafka_producer.send('iot_events', sensor_data)

mqtt_client = mqtt.Client()
mqtt_client.on_connect = on_connect
mqtt_client.on_message = on_message
mqtt_client.connect("iot.local", 1883, 60)
```

### Smart Home Integration
```python
# Integration with Nest/Ecobee
def get_thermostat_data():
    response = requests.get('https://api.nest.com/devices/thermostats', 
                          headers={'Authorization': f'Bearer {token}'})
    return response.json()
```

### Industrial Sensors
```python
# Modbus/OPC-UA integration
from pymodbus.client.sync import ModbusTcpClient

def read_plc_data():
    client = ModbusTcpClient('192.168.1.100')
    result = client.read_holding_registers(0, 10)
    return {"temperature": result.registers[0] / 10.0}
```

## 🚀 Production Deployment

### Cloud Deployment
- **AWS**: EKS + MSK (Managed Kafka) + EMR (Managed Spark)
- **Azure**: AKS + Event Hubs + HDInsight  
- **GCP**: GKE + Kafka on Compute Engine + Dataproc

### Scaling Considerations
- Add more Kafka brokers for higher throughput
- Increase Spark workers for parallel processing
- Use S3/HDFS for checkpoint and output storage
- Add monitoring with Prometheus + Grafana

## 🛡️ Troubleshooting

### Common Issues

**Services won't start:**
```bash
# Check Docker resources
docker system df
docker system prune  # Clean up if needed

# Rebuild from scratch
./docker-dev.sh clean
./docker-dev.sh start
```

**Port conflicts:**
```bash
# Check what's using ports
lsof -i :8080
lsof -i :9092
```

**Code changes not reflected:**
```bash
# Verify volume mounts
docker exec realtime-spark-dev ls -la /app

# Check if files are mounted correctly
./docker-dev.sh spark-sh
pwd && ls -la
```

**Spark job fails:**
```bash
# Check Spark logs
./docker-dev.sh logs spark-dev

# Check if Kafka is accessible
docker exec realtime-spark-dev nc -zv kafka 29092
```

### Reset Everything
```bash
./docker-dev.sh clean  # Removes all data
./docker-dev.sh start  # Fresh start
```

## 📈 Next Steps

1. **Add Real Data Sources**: Replace fake producer with actual sensors/APIs
2. **Advanced Processing**: Add machine learning models, complex aggregations
3. **Monitoring**: Add alerts, dashboards, health checks
4. **Scaling**: Deploy to cloud with auto-scaling
5. **Multiple Outputs**: Add databases, real-time dashboards, notification systems

## 🎯 Key Benefits

- ✅ **Zero Local Setup**: Everything in Docker
- ✅ **Live Development**: Code changes reflect immediately  
- ✅ **Production-Ready**: Same containers for dev and production
- ✅ **Fault Tolerant**: Automatic recovery and checkpointing
- ✅ **Scalable**: Easy to add more producers/consumers
- ✅ **Observable**: Complete monitoring and logging

---

**Happy Streaming! 🚀**