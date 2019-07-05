# Kafka & Portworx Example

## Background

Benchmark numbers and Kafka broker config are based off the tests found from this LinkedIn [article](https://engineering.linkedin.com/kafka/benchmarking-apache-kafka-2-million-writes-second-three-cheap-machines).

## How to Setup - New Cluster on AKS

For a fresh install, you can simply execute `sh install.sh` in this folder. This bash script will create a new resource group, a new AKS cluster and setup the cluster with the strimzi Kafka operator. You can customize the cluster by setting the following environment variables.

```bash
export CLUSTER_NAME="kafka-k8-cluster"
export RG_NAME="kafka-k8-experiments"
export LOCATION="eastus2"
export NODE_SIZE="Standard_DS5_v2"
export NODE_COUNT="3"
export AZURE_TENANT_ID=""
export AZURE_CLIENT_ID=""
export AZURE_CLIENT_SECRET=""
```

The default Kafka CRD installed by the script is the in `portworx/kafka-ss.yaml` which is configured with `portworx` storage class that replicates the volumes 3x. 

To run the performance test for this Kafka configuration, you can run the `sh ./perftest.sh` script as is after the installation setup is completed.

## How to Setup - Existing Cluster on AKS

If you have an existing cluster that you would like to use. You can run the following commands to install the Strimzi operator and setup the Kafka cluster.


```bash
# Create a secret to give Portworx access to Azure APIs
kubectl create secret generic -n kube-system px-azure --from-literal=AZURE_TENANT_ID="" \
--from-literal=AZURE_CLIENT_ID=""\
--from-literal=AZURE_CLIENT_SECRET=""

kubectl apply -f portworks/px-spec.yaml

kubectl create -f portworx/px-ha-sc.yaml

kubectl create -f portworx/zk-config.yaml 
kubectl create -f portworx/zk-config-ss.yaml 

kubectl create -f portworx/kafka-config.yaml 
kubectl create -f portworx/kafka-ss.yaml 

kubectl create -f kafkaclient.yaml
```

To run the performance test for this Kafka configuration, you can run the `sh ./perftest.sh` script as is.

> Note: There are alternative ways to install the Portworx spec configuration. You can choose to apply yaml directly as we display above or customize the portworx volume config through the web interface that generates a url for your portworx installation:

> https://docs.portworx.com/portworx-install-with-kubernetes/cloud/azure/aks/2-deploy-px/#

> Note: Although we create a Kafka Topic using a CRD. You do not need to follow this pattern and can create a Kafka topic directly. The operator will actually mirror topics in the cluster with Kubernetes resources and vice versa.

## How to Customize - Kafka Cluster

You can customize the Kafka configuration by starting with `kafka-ss` which deploys a Kafka cluster that listens on both the plaintext. You can then proceed to configure your cluster using the [Portworx documentation](https://portworx.com/run-ha-kafka-azure-kubernetes-service/).
