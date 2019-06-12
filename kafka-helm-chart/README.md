## Run

This script assumes you already have the Azure CLI and kubectl already installed.

If you wish to use an existing cluster, comment out the below lines in ```install.sh```:

```bash
az group create -n $RG_NAME -l $LOCATION
az aks create -n $CLUSTER_NAME -g $RG_NAME -l $LOCATION --generate-ssh-keys
az aks get-credentials -n $CLUSTER_NAME -g $RG_NAME --overwrite-existing
```

Be sure to change the ```CLUSTER_NAME```, ```RG_NAME``` and ```LOCATION``` in ```install.sh``` to corresponding values from your deployment.

```bash
export CLUSTER_NAME="kafka-k8-cluster"
export RG_NAME="kafka-k8"
export LOCATION="westus2"
```

### Running the script

Run ```./install.sh```

This script will install a Kafka instance with three brokers and three Zookeeper instances on your AKS cluster, with external access via a loadbalancer. Currently it only supports PLAINTEXT authentication.

## Test

Once the installation is complete, you can test the Kafka cluster.

To see the public IPs:

```bash
kubectl get svc
```

To list the topics on this Kafka cluster:

```bash
kubectl exec kafkaclient -- ./bin/kafka-topics.sh --zookeeper kafka-zookeeper:2181 --list
```

To create a topic ```test``` on the Kafka cluster with 4 partitions:

```bash
kubectl exec kafkaclient -- ./bin/kafka-topics.sh --create --zookeeper kafka-zookeeper:2181 --replication-factor 1 --partitions 4 --topic test
```

### Using Kafkacat

You can easily test functionality with kafkacat

To install kafkacat:

```bash
sudo apt-get install kafkacat
```

To list topics, brokers and other metadata:

```bash
kafkacat -b <publicIP> -L
```

**To create producer from command-line:**

Enter below command. Just type (or paste) your message into the terminal and hit enter after that.
Once you’re done just hit control+C

```bash
kafkacat -b </publicIP>/:31090 -t new_topic -P
```

**To create consumers from command-line:**

Enter below command. Once you’re done just hit control+C

```bash
kafkacat -b </publicIP>/:31090 -t new_topic -C
```
