#!/bin/sh

CONSUMER_CONFIG="bootstrap.servers=$CONSUMER_IP\nclient.id=$CONSUMER_CLIENT_ID\ngroup.id=$CONSUMER_GROUP_ID\nexclude.internal.topics=true"
echo $CONSUMER_CONFIG > consumer.config

PRODUCER_CONFIG="bootstrap.servers=$PRODUCER_IP\nclient.id=$PRODUCER_CLIENT_ID\nsasl.mechanism=PLAIN\nsecurity.protocol=SASL_SSL\nsasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username=\"\$ConnectionString\" password=\"$PRODUCER_PASSWORD\";"
echo $PRODUCER_CONFIG > producer.config

echo $CONSUMER_CONFIG
echo $PRODUCER_CONFIG

/usr/bin/kafka-mirror-maker --consumer.config /usr/src/mirror-maker/consumer.config --producer.config /usr/src/mirror-maker/producer.config --whitelist=".*"