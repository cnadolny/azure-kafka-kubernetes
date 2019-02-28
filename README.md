# kafka-kubernetes

Assumes you already have the Azure CLI and kubectl already installed.

Run ./install.sh to optionally provision a cluster, as well as a Kafka instance with two brokers and two Zookeeper instances on your AKS cluster, with external access via a loadbalancer.

Run kubectl get svc to see the public IPs. You can easily test functionality with kafkacat:


sudo apt-get install kafkacat

kafkacat -b <publicup> -L
  
