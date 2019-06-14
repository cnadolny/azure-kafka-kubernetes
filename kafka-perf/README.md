# Kafka Perf Testing

## Background

Benchmark numbers and Kafka broker config are based off the tests found from this LinkedIn article:
https://engineering.linkedin.com/kafka/benchmarking-apache-kafka-2-million-writes-second-three-cheap-machines

## How To Setup - New Cluster and Helm Chart

For full install, including a 7 node AKS Cluster of VM size DS4_V2, Kafka Helm chart, and Kafka client pod, run:

`sh install.sh`

If you have an existing AKS Cluster, add in the resource group and cluster name, and comment out the following lines:

`
az group create -n $RG_NAME -l $LOCATION
az aks create -n $CLUSTER_NAME -g $RG_NAME -l $LOCATION --node-count 7 --node-vm-size Standard_DS4_v2 --generate-ssh-keys
az aks get-credentials -n $CLUSTER_NAME -g $RG_NAME --overwrite-existing
`

To verify that each broker is on its own node, run:

`kubectl get pods -o wide --sort-by="{.spec.nodeName}"`

## How to Setup - Existing Cluster/Helm Chart

If you have an existing cluster and Kafka on Kubernetes instance, you can quickly test it out using the testclient pod.

First, install the pod:

`kubectl apply -f testclient.yaml`

Some sample commands to test out, replacing with your own Zookeeper and Kafka:

`kubectl exec -it testclient -- bin/kafka-topics.sh --zookeeper <your-zookeeper>:2181 --create --topic test-rep-one --partitions 6 --replication-factor 1`

`kubectl exec -it testclient -- bin/kafka-producer-perf-test.sh --topic test-one-rep --num-records 50000000 --record-size 100 --throughput -1 --producer-props acks=1 bootstrap.servers=<your-kafka>:9092 buffer.memory=67108864 batch.size=8196`



## How to Run

Update the environment variables found in commands.sh. To get your Kafka and Zookeeper names, run the following, with the desired namespace if needed:
`kubectl get services --namespace default`

You should see an output like this:

```
kafka                      ClusterIP   10.0.172.51    <none>        9092/TCP                     37m
kafka-headless             ClusterIP   None           <none>        9092/TCP                     37m
kafka-zookeeper            ClusterIP   10.0.172.246   <none>        2181/TCP                     37m
kafka-zookeeper-headless   ClusterIP   None           <none>        2181/TCP,3888/TCP,2888/TCP   37m
kubernetes                 ClusterIP   10.0.0.1       <none>        443/TCP                      57m
```

Where in this example, KAFKA_BROKER_NAME=kafka-headless and ZOOKEEPER_NAME=kafka-zookeeper-headless .

Once your environment variables are updated, run the tests with:

`sh commands.sh`
