#! /usr/bin/env bash

echo "Running script to create Kafka on Kubernetes cluster"

export CLUSTER_NAME="kafka-k8-cluster-strimzi"
export RG_NAME="kafka-k8"
export LOCATION="eastus2"
export NODE_SIZE="Standard_DS5_v2"
export NODE_COUNT="3"

. ../utils/aks_setup.sh

echo "Creating namespace kafka"
kubectl create namespace kafka

echo "Installing Strimzi Kafka Operator"

helm repo add strimzi http://strimzi.io/charts/
helm install strimzi/strimzi-kafka-operator --namespace kafka --name kafka-operator

echo "Installing Kafka"

# Swap following lines if you don't want to use ssl.
#kubectl create -n kafka -f simple-kafka.yaml
kubectl create -n kafka -f tls-kafka.yaml

kubectl create -n kafka -f kafka-topics.yaml
kubectl create -n kafka -f kafka-users.yaml

### Kafka Perf test:
kubectl create -n kafka -f kafkaclient.yaml
