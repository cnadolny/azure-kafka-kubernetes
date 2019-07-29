# uReplicator on Strimzi Operator

## Exposing Zookeeper

By design, Zookeeper is not accessible on the Strimzi operator. It is possible to expose zookeeper internally like so:

https://github.com/strimzi/strimzi-kafka-operator/issues/1337

The service was deployed with an internal load balancer to not worry about zookeeper external authentication. In order to deploy the service with an internal load balancer, an AKS cluster with preview features will need to be created:
https://docs.microsoft.com/en-us/azure/aks/load-balancer-standard

## Issues

Was unable to successfully replicate topics using an unauthenticated endpoint. All pieces deployed successfully onto the cluster with no errors, but replication was unsuccessful upon testing.

## References

https://github.com/uber/uReplicator
https://github.com/unchartedsky/dockerized-ureplicator