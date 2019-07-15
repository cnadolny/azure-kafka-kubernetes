#! /usr/bin/env bash

# Set correct values for your Kafka Cluster
if [ -z "$KAFKA_BROKER_NAME" ]; then
      KAFKA_BROKER_NAME="kafka-broker.default"
fi
if [ -z "$ZOOKEEPER_NAME" ]; then
      # This doesn't work - can't connect directly to zookeeper
      ZOOKEEPER_NAME="zk-headless"
fi
if [ -z "$NUM_RECORDS" ]; then
      NUM_RECORDS=50000000
fi
if [ -z "$RECORD_SIZE" ]; then
      RECORD_SIZE=100
fi
if [ -z "$THROUGHPUT" ]; then
      THROUGHPUT=-1
fi
if [ -z "$BUFFER_MEMORY" ]; then
      BUFFER_MEMORY=67108864
fi

# Create topics
 kubectl exec -n default -it kafka-0 -- bin/kafka-topics.sh --zookeeper $ZOOKEEPER_NAME --create --topic test-one-rep --partitions 6 --replication-factor 1
# kubectl exec -it kafkaclient-0 -- bin/kafka-topics.sh --zookeeper $ZOOKEEPER_NAME --create --topic test --partitions 6 --replication-factor 3 

echo "Single thread, no replication"

echo $KAFKA_BROKER_NAME
kubectl exec -n default -it kafka-0 -- bin/kafka-producer-perf-test.sh \
  --topic test-one-rep --num-records $NUM_RECORDS --record-size $RECORD_SIZE \
  --throughput $THROUGHPUT --producer-props \
  acks=1 bootstrap.servers=$KAFKA_BROKER_NAME:9092 buffer.memory=$BUFFER_MEMORY batch.size=8196 \

exit 1

kubectl exec -it kafkaclient-0 -- bin/kafka-producer-perf-test.sh --topic test-one-rep --num-records $NUM_RECORDS \
       --record-size $RECORD_SIZE --throughput $THROUGHPUT --producer-props acks=1 bootstrap.servers=$KAFKA_BROKER_NAME \
       buffer.memory=$BUFFER_MEMORY batch.size=8196

exit 1

echo "Single-thread, async 3x replication"
kubectl exec -it kafkaclient-0 -- bin/kafka-producer-perf-test.sh --topic test --num-records $NUM_RECORDS --record-size $RECORD_SIZE --throughput $THROUGHPUT --producer-props acks=1 bootstrap.servers=$KAFKA_BROKER_NAME buffer.memory=$BUFFER_MEMORY batch.size=8196

echo "Single-thread, sync 3x replication"
kubectl exec -it kafkaclient-0 -- bin/kafka-producer-perf-test.sh --topic test --num-records $NUM_RECORDS --record-size $RECORD_SIZE --throughput $THROUGHPUT --producer-props acks=-1 bootstrap.servers=$KAFKA_BROKER_NAME buffer.memory=$BUFFER_MEMORY batch.size=64000

echo "Three Producers, 3x async replication"
kubectl exec -it kafkaclient-0 -- bin/kafka-producer-perf-test.sh --topic test --num-records $NUM_RECORDS --record-size $RECORD_SIZE --throughput $THROUGHPUT --producer-props acks=1 bootstrap.servers=$KAFKA_BROKER_NAME buffer.memory=$BUFFER_MEMORY batch.size=8196 && kubectl exec -it kafkaclient-1 -- bin/kafka-producer-perf-test.sh --topic test --num-records $NUM_RECORDS --record-size $RECORD_SIZE --throughput $THROUGHPUT --producer-props acks=1 bootstrap.servers=$KAFKA_BROKER_NAME buffer.memory=$BUFFER_MEMORY batch.size=8196 && kubectl exec -it kafkaclient-2 -- bin/kafka-producer-perf-test.sh --topic test --num-records $NUM_RECORDS --record-size $RECORD_SIZE --throughput $THROUGHPUT --producer-props acks=1 bootstrap.servers=$KAFKA_BROKER_NAME buffer.memory=$BUFFER_MEMORY batch.size=8196

# Throughput Versus Stored Data - this is a long, memory intensive test. Uncomment and use with caution
# kubectl exec -it kafkaclient-0 -- bin/kafka-topics.sh --zookeeper kafka-zookeeper:2181 --create --topic test-throughput --partitions 6 --replication-factor 3 
# kubectl exec -it kafkaclient-1 -- bin/kafka-producer-perf-test.sh --topic test-throughput --num-records 50000000000 --record-size $RECORD_SIZE --throughput $THROUGHPUT --producer-props acks=1 bootstrap.servers=$KAFKA_BROKER_NAME buffer.memory=$BUFFER_MEMORY batch.size=8196

