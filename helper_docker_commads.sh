airflow -h
airflow plugins

alias ll='ls -lG'
alias lls='ls -hlS'


#Login to docker with airflow user
docker exec -it airflow-worker  /bin/bash

#Login to docker with root user
docker exec -it -u root airflow-worker /bin/bash

#Login to docker with airflow user and join the airflow-network
docker exec -it --network airflow-network airflow-worker /bin/bash

# Login to airflow-worker container and test the DAG task
# airflow tasks test <DAG_ID> <TASK_ID> <DATE>
airflow tasks test forex_rk is_forex_rates_available 2023-05-26


