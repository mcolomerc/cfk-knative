#!/bin/sh


NAMESPACE=knative-serving
kubectl proxy &
kubectl get namespace $NAMESPACE -o json |jq '.spec = {"finalizers":[]}' >temp.json
curl -k -H "Content-Type: application/json" -X PUT --data-binary @temp.json 127.0.0.1:8001/api/v1/namespaces/$NAMESPACE/finalize

NAMESPACE=knative-eventing
kubectl proxy &
kubectl get namespace $NAMESPACE -o json |jq '.spec = {"finalizers":[]}' >temp.json
curl -k -H "Content-Type: application/json" -X PUT --data-binary @temp.json 127.0.0.1:8001/api/v1/namespaces/$NAMESPACE/finalize

echo "Clean"
echo "----------------"
kubectl delete -f https://github.com/knative/operator/releases/download/knative-v1.9.3/operator.yaml
 

echo "Delete the Knative Serving.."
echo "--------------------------"
kubectl delete -f ${PWD}/knative/serving.yaml 

echo "Default Domain"
echo "--------------------------"
kubectl delete -f https://github.com/knative/serving/releases/download/knative-v1.9.2/serving-default-domain.yaml

echo "Delete the Knative Eventing.  It will create the knative-eventing namespace."
echo "--------------------------"
kubectl delete -f ${PWD}/knative/eventing.yaml

echo "KafkaSource controller"
echo "--------------------------"
kubectl delete -f https://github.com/knative-sandbox/eventing-kafka-broker/releases/download/knative-v1.9.4/eventing-kafka-controller.yaml

echo "Kafka Source data plane" 
echo "--------------------------"
kubectl delete -f https://github.com/knative-sandbox/eventing-kafka-broker/releases/download/knative-v1.9.4/eventing-kafka-source.yaml 

echo "Delete KafkaSource"
echo "--------------------------"
kubectl delete -f ${PWD}/knative/kafka-source.yaml

echo "Delete Event Consumer"
echo "--------------------------"
kubectl delete -f ${PWD}/knative/event-consumer.yaml

