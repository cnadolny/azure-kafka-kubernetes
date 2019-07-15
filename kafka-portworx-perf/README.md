# Kafka & Portworx Example

## Background

Benchmark numbers and Kafka broker config are based off the tests found from this LinkedIn [article](https://engineering.linkedin.com/kafka/benchmarking-apache-kafka-2-million-writes-second-three-cheap-machines).

## How to Setup - New Cluster on AKS

For a fresh install, you can simply execute `sh install.sh` in this folder. This bash script will create a new resource group, a new AKS cluster and setup the cluster with the Strimzi Kafka operator. You can customize the cluster by setting the following environment variables.

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

## How to interact with Portworx

Portworx creates volumes inside your Kubernetes deployment that it issues as part of the Portworx ASG or cloud drive management. The same drives attach to the new instances automatically. For AKS deployments you can find the new disks inside your resource group with the handle `PX_DO_NOT_DELETE`. In the spec yaml used for Portworx, it defines the volumes/disk and nodes to be allocated to the cluster.

You can use the `pxctl` command Portworx provides to obtain metrics on how the volumes are being used: 
1. First get the name of a Portworx pod.

> `kubectl get pods -n=kube-system -l name=portworx`

2. Next grab the Portworx volume list which will give details on the provisioned volumes deployed. In this Kafka example we define the size and replica amount of the volumes in our statefulset yaml for Kafka and zookeeper.

> `kubectl exec <portowrx_pod_name> -n kube-system -- /opt/pwx/bin/pxctl volume list`

```
ID                      NAME                                            SIZE    HA      SHARED  ENCRYPTED       IO_PRIORITY     STATUS                    SNAP-ENABLED
1055831288650462238     pvc-49e634a1-a3fd-11e9-872e-82275ba87b13        2 GiB   3       no      no              LOW             up - attached on 10.240.0.4no
144040088767070054      pvc-62df858e-a3fd-11e9-872e-82275ba87b13        2 GiB   3       no      no              LOW             up - attached on 10.240.0.5no
1003379156323793182     pvc-6394d9b7-a3fc-11e9-872e-82275ba87b13        2 GiB   3       no      no              LOW             up - attached on 10.240.0.6no
924341013124639820      pvc-653a7482-a3fc-11e9-872e-82275ba87b13        20 GiB  3       no      no              LOW             up - attached on 10.240.0.6no
283085716488210125      pvc-b3afc5cf-a3fd-11e9-872e-82275ba87b13        20 GiB  3       no      no              LOW             up - attached on 10.240.0.5no
935420839169754560      pvc-c32f46f5-a3fd-11e9-872e-82275ba87b13        20 GiB  3       no      no              LOW             up - attached on 10.240.0.4no
nmrose@MININT-86O9IGE:/mnt/c/Users/naros/Desktop/Microsoft/fy20/chubb/portworx/azure-kafka-kubernetes$ kubectl exec portworx-95vrn -n kube-system -- /opt/p
```
3. Now grab the volume state details for a portworx disk. 

> kubectl exec portworx-95vrn -n kube-system -- /opt/pwx/bin/pxctl volume inspect <volume_id>

```
Volume  :  924341013124639820
        Name                     :  pvc-653a7482-a3fc-11e9-872e-82275ba87b13
        Group                    :  kafka_vg
        Size                     :  20 GiB
        Format                   :  ext4
        HA                       :  3
        IO Priority              :  LOW
        Creation time            :  Jul 11 16:59:15 UTC 2019
        Shared                   :  no
        Status                   :  up
        State                    :  Attached: 2e491f27-4345-44be-88ee-fe57ba273efd (10.240.0.6)
        Device Path              :  /dev/pxd/pxd924341013124639820
        Labels                   :  group=kafka_vg,io_priority=high,namespace=default,pvc=data-kafka-0,repl=3
        Reads                    :  49
        Bytes Read               :  425984
        Writes                   :  253363
        Writes MS                :  8695884
        Bytes Written            :  23229157376
        IOs in progress          :  0
        Bytes used               :  1.8 GiB
        Replica sets on nodes:
                Set 0
                  Node           : 10.240.0.4 (Pool 0)
                  Node           : 10.240.0.6 (Pool 0)
                  Node           : 10.240.0.5 (Pool 0)
        Replication Status       :  Up
        Volume consumers         :
                - Name           : kafka-0 (fc673cc0-a4df-11e9-be84-168b323f0e4a) (Pod)
                  Namespace      : default
                  Running on     : aks-nodepool1-13284751-1
                  Controlled by  : kafka (StatefulSet)
```
For details on how to snapshot volumes using stork check out - https://portworx.com/run-ha-kafka-azure-kubernetes-service/.