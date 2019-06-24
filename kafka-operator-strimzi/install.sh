#! /usr/bin/env bash

echo "Running script to create Kafka on Kubernetes cluster"

# Set correct values for your subscription
if [ -z "$CLUSTER_NAME" ]; then
  CLUSTER_NAME="kafka-k8-cluster"
fi
if [ -z "$RG_NAME" ]; then
  RG_NAME="kafka-k8-experiments"
fi
if [ -z "$LOCATION" ]; then
  LOCATION="eastus2"
fi
if [ -z "$NODE_SIZE" ]; then
  NODE_SIZE="Standard_DS5_v2"
fi
if [ -z "$NODE_COUNT" ]; then
  NODE_COUNT="3"
fi

echo "Creating AKS Cluster."

az group create -n $RG_NAME -l $LOCATION
az aks create -n $CLUSTER_NAME -g $RG_NAME -l $LOCATION -c "$NODE_COUNT" -s "$NODE_SIZE" --generate-ssh-keys
az aks get-credentials -n $CLUSTER_NAME -g $RG_NAME --overwrite-existing

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

until kubectl get pods --all-namespaces | grep -E "kube-system(\s){3}tiller.*1\/1\s*Running+"
do
  sleep ${wait}
done

echo "Creating namespace kafka"
kubectl create namespace kafka

echo "Installing Strimzi Kafka Operator"

curl -L https://github.com/strimzi/strimzi-kafka-operator/releases/download/0.12.1/strimzi-cluster-operator-0.12.1.yaml \
  | sed 's/namespace: .*/namespace: kafka/' \
  | kubectl -n kafka apply -f -

echo "Installing Kafka"

# Swap following lines if you don't want to use ssl.
#kubectl create -n kafka -f simple-kafka.yaml
kubectl create -n kafka -f tls-kafka.yaml

kubectl create -n kafka -f kafka-topics.yaml
kubectl create -n kafka -f kafka-users.yaml

### Kafka Perf test:
kubectl create -n kafka -f kafkaclient.yaml
