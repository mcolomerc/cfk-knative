# Confluent For Kubernetes and Knative

Requires:

- OpenSSL
- Helm
- Kubectl
  
## Confluent For Kubernetes

- Install Confluent Platform. Script: `./confluent/deploy.sh`

Autogenerated certificates are used for the Confluent Platform components.

**License**: Configure the Confluent Platform license key(`./confluent/values.yaml`):
  
```yaml
licenseKey: "<license-key>"
```

Deploy script will execute:

- Generate a CA pair to use.
- Create the `confluent` namespace.
- Create a Kubernetes secret for the certificate authority:
- Deploy Confluent For Kubernetes with Helm
- Confluent Platform deployment (Zookeeper, Kafka, Schema Registry, Control Center, Connect, KSQLDB, REST Proxy)
- Exposing services with Ingress
  - Verify: [https://connect.$INGRESS_IP.sslip.io](https://connect.$INGRESS_IP.sslip.io)
  - Verify: [https://controlcenter.$INGRESS_IP.sslip.io](https://controlcenter.$INGRESS_IP.sslip.io)
- Topics:
  - `pageviews`
  - `pageviews.with.schema`
- Connectors:
  - Datagen source connector -> pageviews
  - Datagen source connector -> pageviews with Schema

---

## KNative

Deploy script will execute (`./knative/deploy.sh`):

- Install KNative Operator
- Deploy the Knative Serving. It will create the `knative-serving` namespace.
  - [Kourier](https://github.com/knative-sandbox/net-kourier) enabled.
- Deploy the Knative Eventing. It will create the `knative-eventing` namespace.
- Deploy the KafkaSource controller. Brings Apache Kafka messages into Knative.
  The KafkaSource reads events from an Apache Kafka Cluster, and passes these events to a sink so that they can be consumed.
  - Kafka connection
  - Topics to subscribe
- Sink. Event consumer. A simple application that logs the events received.

### Get Logs

Event Consumer Logs:

`kubectl logs --selector='serving.knative.dev/service=event-display' -c user-container -n confluent`
