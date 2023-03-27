#!/bin/sh

echo "Clean up"
echo "--------------------------"
kubectl delete secret ca-pair-sslcerts -n confluent
kubectl delete secret credential -n confluent

kubectl delete -f ${PWD}/confluent/platform/confluent-platform.yaml
kubectl delete -f ${PWD}/confluent/topics/pageviews.yaml
kubectl delete -f ${PWD}/confluent/topics/pageviews.with.schema.yaml
kubectl delete -f ${PWD}/confluent/connectors/pageviews-connector.yaml
kubectl delete -f ${PWD}/confluent/connectors/pageviews-connector-sr.yaml 


helm delete confluent-operator
helm delete nginx-ingress

NAMESPACE=confluent
kubectl proxy &
kubectl get namespace $NAMESPACE -o json |jq '.spec = {"finalizers":[]}' >temp.json
curl -k -H "Content-Type: application/json" -X PUT --data-binary @temp.json 127.0.0.1:8001/api/v1/namespaces/$NAMESPACE/finalize