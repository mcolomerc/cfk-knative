#!/bin/sh

echo "Install KNative Operator"
echo "----------------"
kubectl apply -f https://github.com/knative/operator/releases/download/knative-v1.9.3/operator.yaml

echo "Verify"
kubectl get deployment knative-operator

echo "Deploy the Knative Serving.  It will create the knative-serving namespace."
echo "--------------------------"
kubectl apply -f ${PWD}/knative/serving.yaml

echo "Verify" 
kubectl get KnativeServing knative-serving -n knative-serving

echo "Default Domain"
echo "--------------------------"
kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.9.2/serving-default-domain.yaml

kubectl apply -f ${PWD}/knative/ingress.yaml

echo "Deploy the Knative Eventing.  It will create the knative-eventing namespace."
echo "--------------------------"
kubectl apply -f ${PWD}/knative/eventing.yaml

echo "KafkaSource controller"
echo "--------------------------"
kubectl apply -f https://github.com/knative-sandbox/eventing-kafka-broker/releases/download/knative-v1.9.4/eventing-kafka-controller.yaml

echo "Kafka Source data plane" 
echo "--------------------------"
kubectl apply -f https://github.com/knative-sandbox/eventing-kafka-broker/releases/download/knative-v1.9.4/eventing-kafka-source.yaml

echo "Verify"
echo "--------------------------"
kubectl get deployments.apps -n knative-eventing

echo "Deploy Event Consumer"
echo "--------------------------" 
kubectl create namespace event-consumers

kubectl apply -f ${PWD}/knative/event-consumer.yaml

echo "Deploy KafkaSource"
echo "--------------------------"
kubectl apply -f ${PWD}/knative/kafka-source.yaml

kubectl describe kafkasource kafka-source -n confluent
 
kubectl logs  kafka-source-dispatcher-0 -n knative-eventing

 