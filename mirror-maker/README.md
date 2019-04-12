# mirror-maker-kubernetes

To run this project, change the following values in the kafka-mm.yaml file:

- CONSUMER\_IP
- PRODUCER\_IP
- PRODUCER\_PASSWORD

Where it is assumed the CONSUMER\_IP is your Kafka
on Kubernetes endpoint, and the PRODUCER\_IP and
PRODUCER\_PASSWORD are your Kafka on
Event Hub Credentials.

Then, apply the deployment:

kubectl -f kafka-mm.yaml

The Dockerfile and run.sh files are provided
if you wish to create and run your own image.
Otherwise, the image provided will work without
any additional needed input from the user.
