#!/bin/bash

echo "Running script to create Kafka on Kubernetes cluster"

# Set correct values for your subscription
export CLUSTER_NAME="kafka-perf"
export RG_NAME="kafka-perf"
export LOCATION="westus2"

export KAFKA_IP_NAME_0="kafka-ip-0"
export KAFKA_IP_NAME_1="kafka-ip-1"
export KAFKA_IP_NAME_2="kafka-ip-2"

echo "Creating AKS Cluster."

az group create -n $RG_NAME -l $LOCATION
az aks create -n $CLUSTER_NAME -g $RG_NAME -l $LOCATION --generate-ssh-keys --node-count 6 
az aks get-credentials -n $CLUSTER_NAME -g $RG_NAME --overwrite-existing

echo "Creating public IPs."

export CLUSTER_RG="$(az aks show -g $RG_NAME -n $CLUSTER_NAME --query nodeResourceGroup -o tsv)"

az network public-ip create -g $CLUSTER_RG -n $KAFKA_IP_NAME_0 --allocation-method static
az network public-ip create -g $CLUSTER_RG -n $KAFKA_IP_NAME_1 --allocation-method static
az network public-ip create -g $CLUSTER_RG -n $KAFKA_IP_NAME_2 --allocation-method static

KAFKA_IP_0="$(az network public-ip show --resource-group $CLUSTER_RG --name $KAFKA_IP_NAME_0 --query ipAddress)"
KAFKA_IP_1="$(az network public-ip show --resource-group $CLUSTER_RG --name $KAFKA_IP_NAME_1 --query ipAddress)"
KAFKA_IP_2="$(az network public-ip show --resource-group $CLUSTER_RG --name $KAFKA_IP_NAME_2 --query ipAddress)"

echo -e "adding RBAC ServiceAccount and ClusterRoleBinding for tiller\n\n"
export timeout=120  #Number of loops before timeout on check on tiller
export wait=5 #Number of seconds between to checks on tiller

kubectl create serviceaccount --namespace kube-system tillersa
if [ $? -ne 0 ]; then
    echo "[ERROR] Creation of tillersa failed"
    # exit 1
fi

kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tillersa
if [ $? -ne 0 ]; then
    echo "[ERROR] Creation of the tiller-cluster-rule failed"
    # exit 1
fi

kubectl create clusterrolebinding dashboard-admin --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard
if [ $? -ne 0 ]; then
    echo "[ERROR] Creation of dashboard-admin failed"
    # exit 1
fi

echo "Upgrading tiller (helm server) to match client version."

helm init --upgrade --service-account tillersa
if [ $? -ne 0 ]; then
    echo "[ERROR] The helm init command failed"
    # exit 1
fi

count=0
until kubectl get pods --all-namespaces | grep -E "kube-system(\s){3}tiller.*1\/1\s*Running+"
do
        sleep ${wait}
done

echo "tiller upgrade complete."

echo "installing kafka helm chart"

cat values.yaml | \
sed 's/\${KAFKA_IP_0}'"/$KAFKA_IP_0/g" | \
sed 's/\${KAFKA_IP_1}'"/$KAFKA_IP_1/g" | \
sed 's/\${KAFKA_IP_2}'"/$KAFKA_IP_2/g" | \
helm install --name kafka-perf incubator/kafka -f -