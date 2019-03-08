# kafka-kubernetes

Modified script from [kow3ns/kubernetes/kafka](https://github.com/kow3ns/kubernetes-kafka/).

## Run

This script assumes you already have the Azure CLI and kubectl already installed.

Run ```./install.sh```. If you wish to provision a cluster, uncomment those lines, otherwise change the CLUSTER_NAME and RG_NAME to your corresponding values. This script will install a Kafka instance with two brokers and two Zookeeper instances on your AKS cluster, with external access via a loadbalancer. Currently it is only via PLAINTEXT authentication.

## Test

To see the public IPs:

```bash
kubectl get svc
```

To list the topics on this Kafka cluster:

```bash
kubectl -n kafka exec testclient -- ./bin/kafka-topics.sh --zookeeper <publicIP>:2181 --list
```

To create a topic ```test``` on the Kafka cluster with 4 partitions:

```bash
kubectl -n kafka exec testclient -- ./bin/kafka-topics.sh --create --zookeeper <zookeeper_IP>:2181 --replication-factor 1 --partitions 4 --topic test
```

### Using Kafkacat

You can easily test functionality with kafkacat

To install kafkacat:

```bash
sudo apt-get install kafkacat
```

To list topics, brokers and other metadata:

```bash
kafkacat -b <publicIP> -L
```

**To create producer from command-line:**

Enter below command. Just type (or paste) your message into the terminal and hit enter after that.
Once you’re done just hit control+C

```bash
kafkacat -b <publicIP>:9092 -t new_topic -P
```

**To create consumers from command-line:**

Enter below command. Once you’re done just hit control+C

```bash
kafkacat -b <publicIP>:9092 -t new_topic -C
```
