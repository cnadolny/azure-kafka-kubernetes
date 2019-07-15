#! /usr/bin/env bash

echo "Running script to create Kafka on Kubernetes cluster"


# Set correct values for your subscription
if [ -z "$CLUSTER_NAME" ]; then
      CLUSTER_NAME="kafka-helm-px"
fi
if [ -z "$RG_NAME" ]; then
      RG_NAME="kafka-helm-rg"
fi
if [ -z "$LOCATION" ]; then
      LOCATION="westus2"
fi
if [ -z "$VM_SIZE" ]; then
      VM_SIZE="Standard_DS5_v2"
fi
if [ -z "$NODE_COUNT" ]; then
      NODE_COUNT=3
fi


. ../utils/aks_setup.sh

echo "installing kafka helm chart"

helm repo add incubator http://storage.googleapis.com/kubernetes-charts-incubator

helm install --name kafka incubator/kafka -f values.yaml

kubectl rollout status statefulset/kafka

kubectl create -f kafkaclient.yaml

echo "Completed installing Kafka Helm chart and client pod."