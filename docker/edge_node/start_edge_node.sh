docker build -t edgenode:latest

docker run -it edgenode:latest /bin/bash

docker run -it --network airflow-network edgenode:latest /bin/bash