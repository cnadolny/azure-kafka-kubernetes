#!/bin/bash

echo "Running script to create Kafka on Kubernetes cluster"
echo "Running script to create Kafka on Kubernetes cluster"

export CLUSTER_NAME="kafka-k8-cluster1"
export RG_NAME="kafka-k81"
export LOCATION="westus2"

# # Uncomment these lines if you would like to create an AKS cluster
# echo "Creating resource group"
# echo ". name:  $RG_NAME"
# az group create -n $RG_NAME -l $LOCATION -o tsv >> log.txt

# echo "Creating AKS cluster"
# echo ".name: $CLUSTER_NAME"
# echo ". location: $LOCATION"
# az aks create -n $CLUSTER_NAME -g $RG_NAME -l $LOCATION --generate-ssh-keys -o tsv >> log.txt

# echo "Setting $CLUSTER_NAME as current context"
# az aks get-credentials -n $CLUSTER_NAME -g $RG_NAME -o tsv >> log.txt

export CLUSTER_RG="$(az aks show -g $RG_NAME -n $CLUSTER_NAME --query nodeResourceGroup -o tsv)"

export KAFKA_IP_NAME_0="kafka_ip_0"
export KAFKA_IP_NAME_1="kafka_ip_1"

echo "Creating public ip"
echo ". name: $KAFKA_IP_NAME_0"
az network public-ip create -g $CLUSTER_RG -n $KAFKA_IP_NAME_0 --allocation-method static -o tsv >> log.txt

KAFKA_IP_0=""
while [ -z $KAFKA_IP_0 ]; do
  KAFKA_IP_0="$(az network public-ip show --resource-group $CLUSTER_RG --name $KAFKA_IP_NAME_0 --query ipAddress --output tsv)"
  [ -z "$KAFKA_IP_0" ] && sleep 10
  echo "Waiting on external IP..."
done
echo "IP created: $KAFKA_IP_0"

echo "Creating public ip"
echo ". name: $KAFKA_IP_NAME_1"
az network public-ip create -g $CLUSTER_RG -n $KAFKA_IP_NAME_1 --allocation-method static >> log.txt

KAFKA_IP_1=""
while [ -z $KAFKA_IP_1 ]; do
  KAFKA_IP_1="$(az network public-ip show --resource-group $CLUSTER_RG --name $KAFKA_IP_NAME_1 --query ipAddress --output tsv)"
  [ -z "$KAFKA_IP_1" ] && sleep 10
  echo "Waiting on external IP..."
done
echo "IP created: $KAFKA_IP_1"

echo "Creating Namespace kafka"
kubectl create namespace kafka

echo "Running zookeeper.yaml"
kubectl create -f zookeeper.yaml

echo "Running kafka.yaml"
cat kafka.yaml | \
sed 's/\$KAFKA_IP_0'"/$KAFKA_IP_0/g" | \
sed 's/\$KAFKA_IP_1'"/$KAFKA_IP_1/g" | \
kubectl apply -f -

for i in {0..1}; do kubectl label pods kafka-$i pod-name=kafka-$i;done

echo "Running testclient.yaml"
kubectl create -f testclient.yaml

echo "Running kubectl get all"
kubectl get all 