#! /usr/bin/env bash

echo "Running script to create Kafka on Kubernetes cluster"

export CLUSTER_NAME="kafka-k8-cluster-banzaicloud"
export RG_NAME="kafka-k8"
export LOCATION="eastus2"
export NODE_SIZE="Standard_DS5_v2"
export NODE_COUNT="3"

. ../utils/aks_setup.sh

echo "Install Zookeeper Operator"

helm repo add banzaicloud-stable https://kubernetes-charts.banzaicloud.com/
helm install --name zookeeper-operator --namespace=zookeeper banzaicloud-stable/zookeeper-operator
kubectl create --namespace zookeeper -f - <<EOF
apiVersion: zookeeper.pravega.io/v1beta1
kind: ZookeeperCluster
metadata:
  name: kafka-zookeeper
  namespace: zookeeper
spec:
  replicas: 3
  persistence:
    spec:
      accessModes:
        - ReadWriteOnce
      storageClassName: managed-premium
      resources:
        requests:
          storage: 32Gi
EOF

echo "Install Kafka BanzaiCloud Operator"

helm install --name=kafka-operator --namespace=kafka banzaicloud-stable/kafka-operator -f ./example-prometheus-alerts.yaml
kubectl create -n kafka -f ./banzaicloud_kafkacluster.yaml

### Kafka Perf test:
kubectl create -f kafkaclient.yaml