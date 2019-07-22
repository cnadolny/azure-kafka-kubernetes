#! /usr/bin/env bash

export LOCATION1=westus2
export LOCATION2=southcentralus
export RG1=mirror-maker-$LOCATION1
export AKS_NAME1=mirror-maker-$LOCATION1
export RG2=mirror-maker-$LOCATION2
export AKS_NAME2=mirror-maker-$LOCATION2
export VNET1=mirror-maker-vnet-$LOCATION1
export VNET2=mirror-maker-vnet-$LOCATION2
export VNET1_PEERING=mm-$LOCATION1-$LOCATION2
export VNET2_PEERING=mm-$LOCATION2-$LOCATION1
export SUBNET_NAME1=aks-subnet-$LOCATION1
export SUBNET_NAME2=aks-subnet-$LOCATION2

az group create -n $RG1 -l $LOCATION1
az group create -n $RG2 -l $LOCATION2
az network vnet create -g $RG1 -n $VNET1 --address-prefix 10.1.0.0/16 --subnet-name $SUBNET_NAME1 --subnet-prefix 10.1.0.0/24
az network vnet create -g $RG2 -n $VNET2 --address-prefix 10.2.0.0/16 --subnet-name $SUBNET_NAME2 --subnet-prefix 10.2.0.0/24

export VNET1_ID=$(az network vnet show -g $RG1 -n $VNET1 --query id --out tsv)
export VNET2_ID=$(az network vnet show -g $RG2 -n $VNET2 --query id --out tsv)

az network vnet peering create -n $VNET1_PEERING -g $RG1 --vnet-name $VNET1 --remote-vnet $VNET2_ID --allow-vnet-access
az network vnet peering create -n $VNET2_PEERING -g $RG2 --vnet-name $VNET2 --remote-vnet $VNET1_ID --allow-vnet-access

export VNET1_SUBNET_ID=$(az network vnet subnet show -g $RG1 -n $SUBNET_NAME1 --vnet-name $VNET1 --query id -o tsv)
export VNET2_SUBNET_ID=$(az network vnet subnet show -g $RG2 -n $SUBNET_NAME2 --vnet-name $VNET2 --query id -o tsv)

az aks create -g $RG1 -n $AKS_NAME1 -l $LOCATION1 --generate-ssh-keys --vnet-subnet-id $VNET1_SUBNET_ID --kubernetes-version 1.14.0 --load-balancer-sku standard --enable-vmss
az aks create -g $RG2 -n $AKS_NAME2 -l $LOCATION2 --generate-ssh-keys --vnet-subnet-id $VNET2_SUBNET_ID --kubernetes-version 1.14.0 --load-balancer-sku standard --enable-vmss

az aks get-credentials -n $AKS_NAME1 -g $RG1 --overwrite-existing

. ../utils/tiller_install.sh

echo "Creating namespace kafka"
kubectl create namespace kafka

echo "Installing Strimzi Kafka Operator"

helm repo add strimzi http://strimzi.io/charts/
helm install strimzi/strimzi-kafka-operator --namespace kafka --name kafka-operator

echo "Installing Kafka"

kubectl create -n kafka -f ../cluster-1.yaml

az aks get-credentials -n $AKS_NAME2 -g $RG2 --overwrite-existing

. ../utils/tiller_install.sh

echo "Creating namespace kafka"
kubectl create namespace kafka

echo "Installing Strimzi Kafka Operator"

helm repo add strimzi http://strimzi.io/charts/
helm install strimzi/strimzi-kafka-operator --namespace kafka --name kafka-operator

echo "Installing Kafka"

kubectl create -n kafka -f ../cluster-2.yaml