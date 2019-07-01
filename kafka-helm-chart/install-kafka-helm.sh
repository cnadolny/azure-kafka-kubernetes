#!/bin/bash

echo "Running script to create Kafka on Kubernetes cluster"

export CLUSTER_NAME="kafka-k8-cluster-helm"
export RG_NAME="kafka-k8"
export LOCATION="westus2"
export NODE_SIZE="Standard_DS5_v2"
export NODE_COUNT="3"

. ../utils/aks_setup.sh

export KAFKA_IP_NAME_0="kafka-ip-0"
export KAFKA_IP_NAME_1="kafka-ip-1"
export KAFKA_IP_NAME_2="kafka-ip-2"

echo "Creating public IPs."
CLUSTER_RG="$(az aks show -g $RG_NAME -n $CLUSTER_NAME --query nodeResourceGroup -o tsv)"
export CLUSTER_RG

az network public-ip create -g "$CLUSTER_RG" -n $KAFKA_IP_NAME_0 --allocation-method static
az network public-ip create -g "$CLUSTER_RG" -n $KAFKA_IP_NAME_1 --allocation-method static
az network public-ip create -g "$CLUSTER_RG" -n $KAFKA_IP_NAME_2 --allocation-method static

KAFKA_IP_0="$(az network public-ip show --resource-group "$CLUSTER_RG" --name $KAFKA_IP_NAME_0 --query ipAddress)"
KAFKA_IP_1="$(az network public-ip show --resource-group "$CLUSTER_RG" --name $KAFKA_IP_NAME_1 --query ipAddress)"
KAFKA_IP_2="$(az network public-ip show --resource-group "$CLUSTER_RG" --name $KAFKA_IP_NAME_2 --query ipAddress)"

echo "adding kafkaClient.yaml"

kubectl create -f kafkaClient.yaml

echo "installing kafka helm chart"

cat values.yaml | \
sed 's/\${KAFKA_IP_0}'"/$KAFKA_IP_0/g" | \
sed 's/\${KAFKA_IP_1}'"/$KAFKA_IP_1/g" | \
sed 's/\${KAFKA_IP_2}'"/$KAFKA_IP_2/g" | \
helm install --name kafka incubator/kafka -f -