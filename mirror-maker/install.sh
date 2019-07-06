export LOCATION1=westus2
export LOCATION2=southcentralus
export RG_NAME1=mirror-maker-$LOCATION1
export AKS_NAME1=mirror-maker-$LOCATION1
export RG_NAME2=mirror-maker-$LOCATION2
export AKS_NAME2=mirror-maker-$LOCATION2
export VNET1=mirror-maker-vnet-$LOCATION1
export VNET2=mirror-maker-vnet-$LOCATION2
export SUBNET_NAME1=aks-subnet-$LOCATION1
export SUBNET_NAME2=aks-subnet-$LOCATION2

az network vnet create -g $RG1 -n $VNET1 --address-prefix 10.1.0.0/16 --subnet-name aks-subnet1 --subnet-prefix 10.1.0.0/24
az network vnet create -g $RG2 -n $VNET2 --address-prefix 10.2.0.0/16 --subnet-name aks-subnet2 --subnet-prefix 10.2.0.0/24

export VNET1_SUBNET_ID = $(az network vnet subnet show -g $RG1 -n $SUBNET_NAME1 --vnet-name $VNET1 --query id -o tsv)
export VNET2_SUBNET_ID = $(az network vnet subnet show -g $RG2 -n $SUBNET_NAME2 --vnet-name $VNET2 --query id -o tsv)

az group create -n $RG1 -l $LOCATION1
az aks create -n $AKS_NAME1 -l $LOCATION1 --generate-ssh-keys --vnet-subnet-id $VNET1_SUBNET_ID

az group create -n $RG2 -l $LOCATION2
az aks create -n $AKS_NAME2 -l $LOCATION2 --generate-ssh-keys --vnet-subnet-id $VNET2_SUBNET_ID

az aks get-credentials -n $AKS_NAME1 -g $RG1 --overwrite-existing

. ../utils/tiller_install.sh

echo "Creating namespace kafka"
kubectl create namespace kafka

echo "Installing Strimzi Kafka Operator"

helm repo add strimzi http://strimzi.io/charts/
helm install strimzi/strimzi-kafka-operator --namespace kafka --name kafka-operator

echo "Installing Kafka"

kubectl create -n kafka -f ../kafka-operator-strimzi/simple-kafka.yaml

kubectl create -f `
apiVersion: v1
kind: Service
metadata:
  name: zk-internal-app
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-internal: "true"
spec:
  type: LoadBalancer
  ports:
  - port: 2181
  selector:
    app: cp-zookeeper`

az aks get-credentials -n $AKS_NAME2 -g $RG2 --overwrite-existing

. ../utils/tiller_install.sh

echo "Creating namespace kafka"
kubectl create namespace kafka

echo "Installing Strimzi Kafka Operator"

helm repo add strimzi http://strimzi.io/charts/
helm install strimzi/strimzi-kafka-operator --namespace kafka --name kafka-operator

echo "Installing Kafka"

kubectl create -n kafka -f ../kafka-operator-strimzi/simple-kafka.yaml