#!/binsh/bash

set -ex

function usageAndExit() {
  echo "Usage:"
  echo ""
  echo -e "--build \t: Build the specified docker image"
  echo -e "--start \t: Start the given service_name using existing docker image"
  echo -e "--restart \t: Restart the given service_name using existing docker image"
  echo -e "--stop \t: Stop the given service_name using existing docker image"
  echo -e "--scale_airflow_worker \t: Scale the airflow worker to the given number "
  echo ""
  echo -e "--cleanup \t: Stop and Cleanup all docker containers, volume, network "
  exit 1
}

function parse_args() {
  while [[ $1 = -* ]]; do
    case $1 in
    --build)
      build_image $2
      shift
      ;;
    --start)
      start_services $2
      shift
      ;;
    --restart)
      restart_service $2
      shift
      ;;
    --stop)
      stop_service $2
      shift
      ;;
    --scale_airflow_worker)
      scale_airflow_worker $2 $3
      shift
      ;;
    --start_edge_node)
      startEdgeNode
      ;;
    --cleanup)
      cleanup
      cleanup_flag=yes
      ;;
    *)
      usageAndExit
      ;;
    esac
    shift
  done

}

function build_airflow_base() {
  export AIRFLOW_VERSION=2.6.1
  export DOCKER_BUILDKIT=1
  docker build docker/airflow/airflow-base \
    --pull \
    --build-arg AIRFLOW_VERSION="${AIRFLOW_VERSION}" \
    --build-arg ADDITIONAL_AIRFLOW_EXTRAS="hdfs,postgres,slack,http,crypto" \
    --tag "airflow-base:${AIRFLOW_VERSION}"
}

function create_docker_network() {
  network_name=$1
  if ! docker network inspect ${network_name} >/dev/null 2>&1; then
    docker network create ${network_name}
  fi
}

function remove_docker_network() {
  network_name=$1
  if docker network inspect ${network_name} >/dev/null 2>&1; then
    docker network rm ${network_name}
  fi
}

function build_hadoop_base() {

  docker build -t hadoop-base docker/hadoop/hadoop-base
  docker build -t hive-base docker/hive/hive-base
  docker build -t spark-base docker/spark/spark-base

  docker build -t hadoop-namenode docker/hadoop/hadoop-namenode
  docker build -t hadoop-datanode docker/hadoop/hadoop-datanode
  docker build -t hadoop-worker docker/hadoop/hadoop-worker

  docker build -t hadoop-historyserver docker/hadoop/hadoop-historyserver
  #docker build -t hadoop-nodemanager docker/hadoop/hadoop-nodemanager
  #docker build -t hadoop-resourcemanager docker/hadoop/hadoop-resourcemanager

  docker build -t hive-metastore docker/hive/hive-metastore
  docker build -t hive-server docker/hive/hive-server
  docker build -t hive-webhcat docker/hive/hive-webhcat

  docker build -t hue docker/hue

  docker build -t spark-master docker/spark/spark-master
  docker build -t spark-worker docker/spark/spark-worker
  docker build -t livy docker/livy

}

function build_image() {
  build_base_image=$1
  docker build -t airflow-postgres docker/postgres
  if [[ ${build_base_image} == 'airflow' ]]; then
    build_airflow_base
  elif [[ ${build_base_image} == 'hadoop' ]]; then
    build_hadoop_base
  elif [[ ${build_base_image} == 'hadoop-airflow' ]]; then
    build_airflow_base
    build_hadoop_base
    export AIRFLOW_IMAGE_NAME=airflow-hadoop:latest
    docker build -t ${AIRFLOW_IMAGE_NAME} docker/airflow/airflow-hadoop
  else
    echo "Wrong Service Name. Please specify either airflow/hadoop/hadoop-airflow"
    exit 1
  fi
}

function start_services() {
  service_name=$1

  create_docker_network airflow-network
  create_docker_network hadoop-network
  create_docker_network dataflow-network

  if [[ ${service_name} == 'airflow' ]]; then
    export AIRFLOW_IMAGE_NAME=airflow-base:2.6.1
    docker compose -f docker-compose-airflow.yml up -d
  elif [[ ${service_name} == 'hadoop' ]]; then
    docker compose -f docker-compose-hadoop.yml up -d
  elif [[ ${service_name} == 'hadoop-airflow' ]]; then
    export AIRFLOW_IMAGE_NAME=airflow-hadoop:latest
    docker compose -f docker-compose-hadoop-airflow.yml --profile hadoop --profile airflow up -d
  elif [[ ${service_name} == 'kafka' ]]; then
    docker compose -f docker/kafka/docker-compose-1-kafka-brokers.yml up -d
  else
    echo "Wrong Service Name. Please specify either airflow/hadoop/hadoop-airflow/kafka"
    exit 1
  fi
}

function restart_service() {
  service_name=$1
  if [[ ${service_name} == 'airflow' ]]; then
    export AIRFLOW_IMAGE_NAME=airflow-base:2.6.1
    docker compose -f docker-compose-airflow.yml down
    start_services $service_name
  elif [[ ${service_name} == 'hadoop' ]]; then
    docker compose -f docker-compose-hadoop.yml down
    start_services $service_name
  elif [[ ${service_name} == 'hadoop-airflow' ]]; then
    docker compose -f docker-compose-hadoop-airflow.yml --profile hadoop --profile airflow down
    start_services $service_name
  elif [[ ${service_name} == 'kafka' ]]; then
    docker volume rm kafka-single-node-volume
    docker compose -f docker/kafka/docker-compose-1-kafka-brokers.yml down
    start_services $service_name
  else
    echo "Wrong Service Name. Please specify either airflow/hadoop/hadoop-airflow/kafka"
    exit 1
  fi

}

function stop_service() {
  service_name=$1
  if [[ ${service_name} == 'airflow' ]]; then
    docker compose -f docker-compose-airflow.yml down #--remove-orphans
  elif [[ ${service_name} == 'hadoop' ]]; then
    docker compose -f docker-compose-hadoop.yml down --remove-orphans
  elif [[ ${service_name} == 'hadoop-airflow' ]]; then
    docker compose -f docker-compose-hadoop-airflow.yml --profile hadoop --profile airflow down --remove-orphans
  elif [[ ${service_name} == 'kafka' ]]; then
    docker compose -f docker/kafka/docker-compose-1-kafka-brokers.yml down
  else
    echo "Wrong Service Name. Please specify either airflow/hadoop/hadoop-airflow/kafka"
    exit 1
  fi
}

function scale_airflow_worker() {
  service_name=$1
  number_of_workers=$2
  if [[ ${service_name} == 'airflow' ]]; then
    docker compose -f docker-compose-${service_name}.yml --scale airflow-worker=$number_of_workers -d
  elif [[ ${service_name} == 'hadoop-airflow' ]]; then
    docker compose -f docker-compose-${service_name}.yml --profile airflow --scale airflow-worker=$number_of_workers -d
  fi
}

function cleanup() {
  docker stop $(docker ps -aq) && docker rm $(docker ps -aq)
  docker system prune -f
  docker volume prune -f
  docker network prune -f
  #docker rmi -f $(docker images -a -q)
}

function startEdgeNode() {
  local build_edge_node_image="NO"

  if [[ $build_edge_node_image == "yes" ]]; then
    if docker stop edgenode >/dev/null 2>&1; then
      docker rm -v edgenode >/dev/null 2>&1
    fi
    docker build -t edgenode:latest docker/edge_node
  fi

  docker run -itd --rm -p 4040-4043:4040-4043 --name edgenode edgenode:latest
  docker network connect airflow-network edgenode
  docker network connect hadoop-network edgenode
  docker network connect dataflow-network edgenode
}

parse_args "$@"
