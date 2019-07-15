# Kafka Operator Strimzi Example

## Background

Benchmark numbers and Kafka broker config are based off the tests found from this LinkedIn [article](https://engineering.linkedin.com/kafka/benchmarking-apache-kafka-2-million-writes-second-three-cheap-machines).

## How to Setup - New Cluster on AKS

For a fresh install, you can simply execute `sh install.sh` in this folder. This bash script will create a new resource group, a new AKS cluster and setup the cluster with the strimzi Kafka operator. You can customize the cluster by setting the following environment variables.

```bash
export CLUSTER_NAME="kafka-k8-cluster"
export RG_NAME="kafka-k8-experiments"
export LOCATION="eastus2"
export NODE_SIZE="Standard_DS5_v2"
export NODE_COUNT="3"
```

The default Kafka CRD installed by the script is the in `tls-kafka.yaml` which is configured with `managed-premium` persistent volume claims, tls side cars for zookeeper and kafka and only listens on the encrypted ports. It will also setup default topics and users.

To run the performance test for this Kafka configuration, you can run the `sh ./perftest.sh` script as is.

## How to Setup - Existing Cluster on AKS

If you have an existing cluster that you would like to use. You can run the following commands to install the Strimzi operator and setup the Kafka cluster.


```bash
kubectl create namespace kafka
helm repo add strimzi http://strimzi.io/charts/
helm install strimzi/strimzi-kafka-operator --namespace kafka --name kafka-operator

kubectl create -n kafka -f tls-kafka.yaml

kubectl create -n kafka -f kafka-topics.yaml
kubectl create -n kafka -f kafka-users.yaml

kubectl create -n kafka -f kafkaclient.yaml
```

To run the performance test for this Kafka configuration, you can run the `sh ./perftest.sh` script as is.

> Note: There are alternative ways to install the Strimzi Kafka Operator. You can choose to apply yaml directly using the following code:

```bash
curl -L https://github.com/strimzi/strimzi-kafka-operator/releases/download/0.12.1/strimzi-cluster-operator-0.12.1.yaml \
  | sed 's/namespace: .*/namespace: kafka/' \
  | kubectl -n kafka apply -f -
```

> Note: Although we create a Kafka Topic using a CRD. You do not need to follow this pattern and can create a Kafka topic directly. The operator will actually mirror topics in the cluster with Kubernetes resources and vice versa.

## How to Customize - Kafka Cluster

You can customize the Kafka configuration by starting with `simple-kafka.yaml` which deploys a Kafka cluster that listens on both the plaintext and tls listeners. You can then proceed to configure your cluster using the [Strimzi documentation](https://strimzi.io/docs/latest/).

## Using the Kafka Shell Scripts

The operator encrypts all connections to Zookeeper using a TLS sidecar and you can't access zookeeper directly. If you want to use any of the bin/kafka* scripts, you should connect to any of the Kafka brokers and specify `--zookeeper localhost:2181` to use the encrypted tunnel.

```bash
kubectl exec -ti my-cluster-kafka-0 -- bin/kafka-topics.sh --list --zookeeper localhost:2181
```
