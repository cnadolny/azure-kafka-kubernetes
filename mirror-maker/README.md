# mirror-maker-kubernetes

To run this project, change the following values in the kafka-mm.yaml file:

- CONSUMER\_IP
- PRODUCER\_ENDPOINT
- PRODUCER\_PASSWORD

Where it is assumed the CONSUMER\_IP is your Kafka
on Kubernetes endpoint, and the PRODUCER\_ENDPOINT and
PRODUCER\_PASSWORD are your Kafka on
Event Hub Credentials.

Then, apply the deployment:

kubectl -f kafka-mm.yaml