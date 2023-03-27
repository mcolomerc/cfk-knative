#!/bin/sh
echo "\n Script executed from: ${PWD}"

exit_on_error() {
    exit_code=$1
    last_command=${@:2}
    if [ $exit_code -ne 0 ]; then
        >&2 echo "\"${last_command}\" command failed with exit code ${exit_code}."
        exit $exit_code
    fi
}



echo "\n Generate a CA pair to use:"
echo "----------------------------------"
openssl genrsa -out ${PWD}/confluent/platform/ca-key.pem 2048
exit_on_error $? !!

# Generate CA key 
openssl req -new -key ${PWD}/confluent/platform/ca-key.pem -x509 \
 -days 1000 \
 -out ${PWD}/confluent/platform/ca.pem \
 -subj "/C=US/ST=CA/L=MountainView/O=Confluent/OU=Operator/CN=TestCA"
exit_on_error $? !!

echo "\n Create confluent namespace"
echo "--------------------------" 
kubectl create namespace confluent

echo "\n Create a Kubernetes secret for the certificate authority:"
echo "--------------------------" 
kubectl create secret tls ca-pair-sslcerts --cert=${PWD}/confluent/platform/ca.pem --key=${PWD}/confluent/platform/ca-key.pem -n confluent

echo "\n Generate secrets"
echo "--------------------------" 
kubectl -n confluent create secret generic credential \
--from-file=plain-users.json=${PWD}/confluent/platform/creds-kafka-sasl-users.json \
--from-file=digest-users.json=${PWD}/confluent/platform/creds-zookeeper-sasl-digest-users.json \
--from-file=digest.txt=${PWD}/confluent/platform/creds-kafka-zookeeper-credentials.txt \
--from-file=plain.txt=${PWD}/confluent/platform/creds-client-kafka-sasl-user.txt \
--from-file=basic.txt=${PWD}/confluent/platform/creds-control-center-users.txt
exit_on_error $? !!

echo "\n Add Helm repos"
echo "--------------------------"
helm repo add confluentinc https://packages.confluent.io/helm
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

echo "\n Deploy the CFK Operator"
echo "--------------------------" 
helm upgrade --install confluent-operator confluentinc/confluent-for-kubernetes --namespace confluent --values ${PWD}/confluent/values.yaml
exit_on_error $? !!

echo "\n NGINX Ingress controller"
echo "--------------------------"  
helm install nginx-ingress ingress-nginx/ingress-nginx
exit_on_error $? !!

echo "\n Confluent Platform Deployment"
echo "--------------------------" 
kubectl apply -f ${PWD}/confluent/platform/confluent-platform.yaml 
exit_on_error $? !!


echo "\n Wait for Kafka pods to be ready"
kubectl wait -l statefulset.kubernetes.io/pod-name=kafka-0 --for=condition=ready pod --timeout=-1s -n confluent
kubectl wait -l statefulset.kubernetes.io/pod-name=kafka-1 --for=condition=ready pod --timeout=-1s -n confluent
kubectl wait -l statefulset.kubernetes.io/pod-name=kafka-2 --for=condition=ready pod --timeout=-1s -n confluent

echo "\n Topics"
echo "--------------------------" 
kubectl apply -f ${PWD}/confluent/topics/pageviews.yaml 
kubectl apply -f ${PWD}/confluent/topics/pageviews.with.schema.yaml

echo "\n Verify"
echo "--------------------------" 
kubectl get topic -n confluent

echo "\n Wait for Kafka Connect pods to be ready"
kubectl wait -l statefulset.kubernetes.io/pod-name=connect-0 --for=condition=ready pod --timeout=-1s -n confluent

echo "\n Connectors"
echo "--------------------------" 
kubectl apply -f ${PWD}/confluent/connectors/pageviews-connector.yaml 
kubectl apply -f ${PWD}/confluent/connectors/pageviews-connector-sr.yaml 

echo "\n Verify"
echo "--------------------------" 
kubectl get connectors -n confluent

echo "\n Deploy ingress" 
echo "--------------------------"  
ip=""
while [ -z $ip ]; do
  echo "Waiting for external IP"
  ip=$(kubectl get svc nginx-ingress-ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  [ -z "$ip" ] && sleep 10
done
echo 'Found external IP: '$ip 
sed -i'' .template "s/<LOADBALANCER_INGRESS>/$ip/g" ${PWD}/confluent/ingress/c3-ingress.yaml
sed -i'' .template "s/<LOADBALANCER_INGRESS>/$ip/g" ${PWD}/confluent/ingress/connect-ingress.yaml

kubectl wait -l statefulset.kubernetes.io/pod-name=controlcenter-0 --for=condition=ready pod --timeout=-1s -n confluent 

kubectl apply -f ${PWD}/confluent/ingress/c3-ingress.yaml
kubectl apply -f ${PWD}/confluent/ingress/connect-ingress.yaml 
