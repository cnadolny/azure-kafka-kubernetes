# kafka-kubernetes

Modified script from [kow3ns/kubernetes/kafka](https://github.com/kow3ns/kubernetes-kafka/).

## Run

This script assumes you already have the Azure CLI and kubectl already installed.

Run ./install.sh. If you wish to provision a cluster, uncomment those lines, otherwise change the CLUSTER_NAME and RG_NAME to your corresponding values. This script will install a Kafka instance with two brokers and two Zookeeper instances on your AKS cluster, with external access via a loadbalancer. Currently it is only via PLAINTEXT authentication.

## Test

Run kubectl get svc to see the public IPs. You can easily test functionality with kafkacat:

sudo apt-get install kafkacat

kafkacat -b \<publicIP\> -L
  
