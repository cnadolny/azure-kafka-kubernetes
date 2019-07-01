#! /usr/bin/env bash

echo "Running script to create Kafka on Kubernetes cluster"

export CLUSTER_NAME="kafka-perf"
export RG_NAME="kafka-perf"
export LOCATION="westus2"
export NODE_SIZE="Standard_DS4_v2"
export NODE_COUNT="7"

. ../utils/aks_setup.sh

echo "installing kafka helm chart"

helm install --name kafka incubator/kafka -f values.yaml

kubectl rollout status statefulset/kafka

kubectl create -f kafkaclient.yaml

echo "Completed installing Kafka Helm chart and client pod."