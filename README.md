This can be used to spin below docker images:
1. Airflow with Celery Executor 
2. A single standalone Hadoop Cluster
3. A single standalone Hadoop Cluster with Airflow Services
4. Start edge node to access hadoop cluster

## Components Versions
1. Hadoop  : 3.2.4
2. Hive    : 3.1.2
3. Spark   : 3.2.1
4. Scala   : 2.12.4
5. Python  : 3
6. SBT     : 1.2.8
7. Airflow : 2.6.5
8. Hue     : 4.10.0
9. Livy    : Latest
10. Postgres: 13

## Pre-requites:
1. Pull the code from Github
2. Create a volume directory anywhere on your system to be used by hadoop and spark to store data
3. Update the below variables in .env file:
   - AIRFLOW_PROJ_DIR: Give the full path of directory where you want to keep your dags
   - HADOOP_DATA_DIR: Provide the full path of volume directory.
4. You can control airflow configuration using conf file: airflow.cfg available under directory AIRFLOW_PROJ_DIR

**Note:**
- Default airflow.cfg is available under <project_base_path>/airflow for reference.
- If env variables are not set, please find below default path
  - airflow dags and conf Path: <project_base_path>/airflow
  - hdfs and spark storage Path: <project_base_path>/volumes/hadoop and <project_base_path>/volumes/spark

## Build Docker Images
Build airflow base Image(airflow-base-2.6.1)
```
sh -x start_services.sh --build airflow
```

Build Base images of all Hadoop and spark components
```
sh -x start_services.sh --build hadoop
```

Build all hadoop and airflow bases images
```
sh -x start_services.sh --build hadoop-airflow
```

## Start Services
Start only Airflow Services
```
sh -x start_services.sh --start airflow
```

Start only Hadoop Services
```
sh -x start_services.sh --start hadoop
```

Start Hadoop with airflow Services
```
sh -x start_services.sh --start hadoop-airflow
```

Airflow services available at: http://localhost:8080/
- username: airflow
- password: airflow


## Re-Start Services
Re-Start only Airflow Services
```
sh -x start_services.sh --restart airflow
```

Re-Start only Hadoop Services
```
sh -x start_services.sh --restart hadoop
```

Re-Start Hadoop with airflow Services
```
sh -x start_services.sh --restart hadoop-airflow
```

## Stop Services
Stop only Airflow Services
```
sh -x start_services.sh --stop airflow
```

Stop only Hadoop Services
```
sh -x start_services.sh --stop hadoop
```

Stop Hadoop with airflow Services
```
sh -x start_services.sh --stop hadoop-airflow
```

## Scale Airflow Worker
```
number_of_workers=2
sh -x start_services.sh --scale_airflow_worker $number_of_workers
```

## Start Edge node to Access hadoop and spark
```
sh -x start_services.sh --start_edge_node
```

## Cleanup all resources: cleanup
```
sh -x start_services.sh --cleanup
```
