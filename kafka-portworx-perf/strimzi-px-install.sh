#! /usr/bin/env bash

echo "Running script to create Kafka on Kubernetes cluster"

export CLUSTER_NAME="nr-strimzi-px-test2"
export RG_NAME="nr-strimzi-px-rg2"
export LOCATION="westus2"
export NODE_SIZE="Standard_DS5_v2"
export NODE_COUNT="3"
export AZURE_TENANT_ID=""
export AZURE_CLIENT_ID=""
export AZURE_CLIENT_SECRET=""

. ../utils/aks_setup.sh

echo "Creating namespace kafka"
kubectl create namespace kafka

echo "Installing Strimzi Kafka Operator"

helm repo add strimzi 

helm install strimzi/strimzi-kafka-operator --namespace kafka --name kafka-operator

echo "Installing Portworx"

# Create a secret to give Portworx access to Azure APIs
kubectl create secret generic -n kube-system px-azure --from-literal=AZURE_TENANT_ID="" \
                                                      --from-literal=AZURE_CLIENT_ID=""\
                                                      --from-literal=AZURE_CLIENT_SECRET=""


# Generate custom specs for your portworx config. By default, the script uses Premium volume types, 150 GB, Auto Data and 
# Management network interfaces with Stork, GUI enabled. To customize this config use the api URL to download a custom yaml
# [https://docs.portworx.com/portworx-install-with-kubernetes/cloud/azure/aks/2-deploy-px/#]

kubectl apply -f 'https://aks-install.portworx.com/2.1?mc=false&kbver=1.12.7&b=true&s=%22type%3DPremium_LRS%2Csize%3D150%22&j=auto&md=type%3DPremium_LRS%2Csize%3D100&c=px-cluster-4148c550-39b2-4954-8a15-fa0cfe584dd8&aks=true&stork=true&lh=true&st=k8s'

until kubectl get pods --all-namespaces | grep -E "kube-system(\s){3}portworx.*1\/1\s*Running+"
do
  sleep ${wait}
done

# Create a storage class defining the storage requirements like replication factor, snapshot policy, and performance profile for kafka
kubectl create -f portworx/px-ha-sc.yaml

echo "Installing Kafka"

# Swap following lines if you don't want to use ssl.
kubectl create -n kafka -f strimzi/simple-kafka.yaml
#kubectl create -n kafka -f strimzi/tls-kafka.yaml

kubectl create -n kafka -f strimzi/kafka-topics.yaml
kubectl create -n kafka -f strimzi/kafka-users.yaml

### Kafka Perf test:
kubectl create -n kafka -f strimzi/kafkaclient.yaml
