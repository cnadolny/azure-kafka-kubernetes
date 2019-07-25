#! /usr/bin/env bash

echo "Running script to create Kafka on Kubernetes cluster"

# Set correct values for your subscription
if [ -z "$CLUSTER_NAME" ]; then
  CLUSTER_NAME="kafka-px-test"
fi
if [ -z "$RG_NAME" ]; then
  RG_NAME="kafka-px-test-rg"
fi
if [ -z "$LOCATION" ]; then
  LOCATION="westus2"
fi
if [ -z "$NODE_SIZE" ]; then
  NODE_SIZE="Standard_DS5_v2"
fi
if [ -z "$NODE_COUNT" ]; then
  NODE_COUNT="3"
fi
if [ -z "$AZURE_TENANT_ID" ]; then
  AZURE_TENANT_ID=""
fi
if [ -z "$AZURE_CLIENT_ID" ]; then
  AZURE_CLIENT_ID=""
fi
if [ -z "$AZURE_CLIENT_SECRET" ]; then
  AZURE_CLIENT_SECRET=""
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

# Configure Zookeeper map to inject portworx customization and deploy a zookeeper statefulset
kubectl create -f portworx/zk-config.yaml 
kubectl create -f portworx/zk-config-ss.yaml 

# Configure kafka map to inject portworx customization and deploy a kafka statefulset
kubectl create -f portworx/kafka-config.yaml 
kubectl create -f portworx/kafka-ss.yaml 

# Configure a kafka cli to make it easier to comunicate with the kafka broker
kubectl create -f kafkaclient.yaml

### Once environment has been successfully deployed, run the kafka perfomance script
