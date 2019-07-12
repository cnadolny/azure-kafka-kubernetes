# Mirror Maker on AKS using Strimzi Kafka Operator
## Install
Apply both cluster-1 and cluster-2 YAML files:
```
kubectl apply -f cluster-1.yaml -n kafka
kubectl apply -f cluster-2.yaml -n kafka
```

Wait for public IP to be allocated, check status of public IP with:
```
kubectl get svc -n kafka
cluster-1-kafka-external-bootstrap   LoadBalancer   10.3.0.196   12.123.123.123   9094:30623/TCP               19h
cluster-2-kafka-external-bootstrap   LoadBalancer   10.3.0.196   23.234.234.234   9094:30623/TCP               19h
```

Grab the IP addresses of the two external bootstrap loadbalancers, and add them into the mirror-maker YAML like so, where the messages will be replicated FROM the CONSUMER_IP TO the PRODUCER_ENDPOINT:
```
- name: "CONSUMER_IP"
    value: "12.123.123.123:9094" 
- name: "PRODUCER_ENDPOINT"
    value: "23.234.234.234:9094" 
```

Apply the mirror maker YAML:
`kubectl apply -f mirror-maker.yaml`

## Testing
To test out your new mirror maker instance, I recommend downloading kafkacat, which is a command line tool that can be used to communicate with your Kafka cluster. It can be install on Debian with:
`apt-get install kafkacat`
or on Max OS with:
`brew install kafkacat`

Open up two terminals, and run the following in each terminal:
```
kafkacat -b 12.123.123.123:9094 -P -t test
kafkacat -b 23.234.234.234:9094 -C -t test
```

Which will demonstrate you producing messaging to topic `test` on endpoint `12.123.123.123:9094`, and those messages will be replicated and consumer on topic `test` on endpoint `23.234.234.234:9094`.