# Start Kafka Cluster
<a href="https://docs.confluent.io/platform/current/platform-quickstart.html/" target="new">Confluent Kafka UI Guide</a>
<br><a href="https://developer.confluent.io/quickstart/kafka-docker/" target="new">Confluent Kakfa Quickstart Guide</a>

## ## Confluent 1 node kafka
    ```
    cd docker/kafka
    docker compose -f docker-compose-1-kafka-brokers.yml up -d
    ```
**In case you want to run this kafka cluster on another machine, then change the
localhost to ipaddress of the host machine and broker address will change to host_id_address:19092**

#### Kafka Broker: localhost:19092
#### Schema Registry URL: http://localhost:18081


## Confluent 3 node kafka
    ```
    cd docker/kafka
    docker compose -f docker-compose-3-kafka-brokers.yml up -d
    ```
#### Kafka Broker: localhost:19092,localhost:29092,localhost:39092
#### Schema Registry URL: http://localhost:18081
