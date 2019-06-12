#! /usr/bin/env bash

echo "Running script to create Kafka on Kubernetes cluster"

# Set correct values for your subscription
if [ -z "$CLUSTER_NAME" ]; then
      CLUSTER_NAME="kafka-k8-cluster"
fi
if [ -z "$RG_NAME" ]; then
      RG_NAME="kafka-k8"
fi
if [ -z "$LOCATION" ]; then
      LOCATION="eastus2"
fi

KAFKA_IP_NAME_0="kafka-ip-0"
KAFKA_IP_NAME_1="kafka-ip-1"
KAFKA_IP_NAME_2="kafka-ip-2"

echo "Creating AKS Cluster."

az group create -n $RG_NAME -l $LOCATION
az aks create -n $CLUSTER_NAME -g $RG_NAME -l $LOCATION --generate-ssh-keys
az aks get-credentials -n $CLUSTER_NAME -g $RG_NAME --overwrite-existing

echo "Creating public IPs."

CLUSTER_RG="$(az aks show -g $RG_NAME -n $CLUSTER_NAME --query nodeResourceGroup -o tsv)"

az network public-ip create -g "$CLUSTER_RG" -n $KAFKA_IP_NAME_0 --allocation-method static
az network public-ip create -g "$CLUSTER_RG" -n $KAFKA_IP_NAME_1 --allocation-method static
az network public-ip create -g "$CLUSTER_RG" -n $KAFKA_IP_NAME_2 --allocation-method static

KAFKA_IP_0="$(az network public-ip show --resource-group "$CLUSTER_RG" --name $KAFKA_IP_NAME_0 --query ipAddress)"
KAFKA_IP_1="$(az network public-ip show --resource-group "$CLUSTER_RG" --name $KAFKA_IP_NAME_1 --query ipAddress)"
KAFKA_IP_2="$(az network public-ip show --resource-group "$CLUSTER_RG" --name $KAFKA_IP_NAME_2 --query ipAddress)"

export KAFKA_IP_0
export KAFKA_IP_1
export KAFKA_IP_2

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

echo "Install Zookeeper Operator"

helm repo add banzaicloud-stable https://kubernetes-charts.banzaicloud.com/
helm install --name zookeeper-operator --namespace=zookeeper banzaicloud-stable/zookeeper-operator
kubectl create --namespace zookeeper -f - <<EOF
apiVersion: zookeeper.pravega.io/v1beta1
kind: ZookeeperCluster
metadata:
  name: example-zookeepercluster
  namespace: zookeeper
spec:
  replicas: 3
EOF

sleep ${wait}

echo "Install Kafka BanzaiCloud Operator"

helm repo add banzaicloud-stable https://kubernetes-charts.banzaicloud.com/
helm install --name=kafka-operator --namespace=kafka banzaicloud-stable/kafka-operator -f ./example-prometheus-alerts.yaml
# Add your zookeeper svc name to the configuration
kubectl create -n kafka -f ./example-secret.yaml
kubectl create -n kafka -f ./banzaicloud_v1alpha1_kafkacluster.yaml