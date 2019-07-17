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

Grab the certificate and create a truststore for both clusters:
```
kubectl get secret cluster1-cluster-ca-cert -n kafka -o jsonpath='{.data.ca\.crt}' | base64 -d > ca1.crt
keytool -keystore client1.truststore.jks -alias CARoot -import -file /etc/cert-volume/ca1.crt
```
```
kubectl get secret cluster2-cluster-ca-cert -n kafka -o jsonpath='{.data.ca\.crt}' | base64 -d > ca1.crt
keytool -keystore client2.truststore.jks -alias CARoot -import -file /etc/cert-volume/ca2.crt
```

Add the truststore path to the YAML file:
```
- name: "PRODUCER_TRUSTSTORE_LOCATION"
value: "/ca1.crt"
- name: "CONSUMER_TRUSTSTORE_LOCATION"
value: "/ca2.crt"
```

Apply the mirror maker YAML:
`kubectl apply -f mirror-maker.yaml`

## Testing
### Testing on Kubernetes pod
Edit the kafka client yaml file, uncomment the 
`kubectl apply -f kafkaClient.yaml`

Exec into the pod:
`kubectl exec -it kafkaclient -- /bin/bash`

Create a `client-ssl.properties` file:
```
bootstrap.servers=<PUBLIC-IP>:9094
security.protocol=SSL
ssl.truststore.location=client.truststore.jks
```

Test out consuming and producing to your TLS secured endpoint:
```
./bin/kafka-console-consumer.sh --bootstrap-server <PUBLIC-IP>:9094 --topic test -consumer.config client-ssl.properties --from-beginning
./bin/kafka-console-producer.sh --broker-list <PUBLIC-IP>:9094 --topic test --producer.config client-ssl.properties
```

#### Creating JKS Truststore
If you would like to test locally or connect with another application, you will need to create a truststore from the stored certificate, which can be obtained and created by the following commands:
```
kubectl get secret <cluster-name>-cluster-ca-cert -n kafka -o jsonpath='{.data.ca\.crt}' | base64 -d > ca.crt
keytool -keystore client.truststore.jks -alias CARoot -import -file /etc/cert-volume/ca.crt
```

### Unauthenticated 
If you would like an endpoint for quick testing or demo purposes, it is possible to create an unauthenticated endpoint.

#### Unauthenticated External Endpoint
To test out your new mirror maker instance, I recommend downloading kafkacat, which is a command line tool that can be used to easily communicate with your Kafka cluster. It can be installed on Debian with:
`apt-get install kafkacat`
or on Max OS with:
`brew install kafkacat`

Open up two terminals, and run the following in each terminal:
```
kafkacat -b 12.123.123.123:9094 -P -t test
kafkacat -b 23.234.234.234:9094 -C -t test
```

Which will demonstrate you producing messaging to topic `test` on endpoint `12.123.123.123:9094`, and those messages will be replicated and consumer on topic `test` on endpoint `23.234.234.234:9094`.

### Internal Load Balancer
