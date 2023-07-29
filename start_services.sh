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
      scale_airflow_worker $2
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
    echo "Wrong Base Image Name. Please specify either airflow/hadoop/hadoop-airflow"
    exit 1
  fi
}

function start_services() {
  service_name=$1
  if [[ ${service_name} == 'airflow' ]]; then
    export AIRFLOW_IMAGE_NAME=airflow-base:2.6.1
    docker compose -f docker-compose-hadoop-airflow.yml --profile airflow up -d
  elif [[ ${service_name} == 'hadoop' ]]; then
    docker compose -f docker-compose-hadoop-airflow.yml --profile hadoop up -d
  elif [[ ${service_name} == 'hadoop-airflow' ]]; then
    export AIRFLOW_IMAGE_NAME=airflow-hadoop:latest
    docker compose -f docker-compose-hadoop-airflow.yml --profile hadoop --profile airflow up -d
  else
    echo "Wrong Service Name. Please specify either airflow/hadoop/hadoop-airflow"
    exit 1
  fi
}

function restart_service() {
  service_name=$1
  if [[ ${service_name} == 'airflow' ]]; then
    export AIRFLOW_IMAGE_NAME=airflow-base:2.6.1
    docker compose -f docker-compose-hadoop-airflow.yml --profile airflow down
    docker compose -f docker-compose-hadoop-airflow.yml --profile airflow up -d
  elif [[ ${service_name} == 'hadoop' ]]; then
    docker compose -f docker-compose-hadoop-airflow.yml --profile hadoop down
    docker compose -f docker-compose-hadoop-airflow.yml --profile hadoop up -d
  elif [[ ${service_name} == 'hadoop-airflow' ]]; then
    export AIRFLOW_IMAGE_NAME=airflow-hadoop:latest
    docker compose -f docker-compose-hadoop-airflow.yml --profile hadoop --profile airflow down
    docker compose -f docker-compose-hadoop-airflow.yml --profile hadoop --profile airflow up -d
  else
    echo "Wrong Service Name. Please specify either airflow/hadoop/hadoop-airflow"
    exit 1
  fi

}

function stop_service() {
  service_name=$1
  if [[ ${service_name} == 'airflow' ]]; then
    docker compose -f docker-compose-hadoop-airflow.yml --profile airflow down
  elif [[ ${service_name} == 'hadoop' ]]; then
    docker compose -f docker-compose-hadoop-airflow.yml --profile hadoop down
  elif [[ ${service_name} == 'hadoop-airflow' ]]; then
    docker compose -f docker-compose-hadoop-airflow.yml --profile hadoop --profile airflow down
  else
    echo "Wrong Service Name. Please specify either airflow/hadoop/hadoop-airflow"
    exit 1
  fi
}

function scale_airflow_worker() {
  number_of_workers=$1
  docker compose -f docker-compose-hadoop-airflow.yml --profile airflow --scale airflow-worker=$number_of_workers -d
}

function cleanup() {
  docker compose -f docker-compose-hadoop-airflow.yml --profile hadoop --profile airflow down
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

  if docker network inspect airflow-network >/dev/null 2>&1; then
    docker run -it --rm --network airflow-network --name edgenode edgenode:latest
  else
    docker run -it --rm --name edgenode edgenode:latest
  fi
}

parse_args "$@"
