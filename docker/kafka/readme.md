# Start Kafka Cluster

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



### Run Kafka CLI Commands:
<a href="https://www.conduktor.io/kafka/kafka-cli-tutorial/" target="new">Confluent Kakfa CLI Commands</a>

- Kafka Topics Management with kafka-topics
- Kafka Producer with kafka-console-producer
- Kafka Consumer with kafka-console-consumer
- Kafka Consumers in Consumer Groups with kafka-console-consumer
- Kafka Consumer Groups management with kafka-consumer-groups

### Login into any of the kafka broker
docker exec -it <CONTAINER_NAME> /bin/bash

```
docker exec -it kafka-kafka-broker-1-1 /bin/bash
```


### kafka topics

```
#Create kafka topic
kafka-topics \
--bootstrap-server localhost:9092 \
--topic first_topic \
--create --partitions 3 \
--replication-factor 1
```

#List kafka topic
```
kafka-topics --list --bootstrap-server localhost:9092
```

### Kafka Producer
```
kafka-console-producer \
--bootstrap-server localhost:9092 \
--topic first_topic
```

```
#Send a message as key values like: 
#SET41:{"CreatedTime": "2019-02-05 09:54:00","Reading": 36.2}
kafka-console-producer \
--bootstrap-server localhost:9092 \
--topic sensor \
--property parse.key=true \
--property key.separator=:
```

### Kafka Consumer
```
kafka-console-consumer \
--bootstrap-server localhost:9092 \
--topic first_topic \
--from-beginning
```
### Schema Registry Commands:
[ConfluentGithub](https://github.com/confluentinc/schema-registry/blob/master/README.md)
</br>[Medium.com](https://ranjitnagi.medium.com/commonly-used-confluent-schema-registry-apis-methods-cf94ce9a68f7)


