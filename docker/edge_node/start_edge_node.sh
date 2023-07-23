docker stop edgenode >/dev/null 2>&1
docker rm -v edgenode >/dev/null 2>&1

docker build -t edgenode:latest docker/edge_node

docker network inspect airflow-network >/dev/null 2>&1
if [ $? -eq 0 ]; then
    docker run -it --network airflow-network edgenode:latest /bin/bash
    docker run -it --rm --network airflow-network --name edgenode edgenode:latest /bin/bash
else
    docker run -it --rm --name edgenode edgenode:latest /bin/bash
fi