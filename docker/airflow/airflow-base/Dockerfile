FROM apache/airflow:2.6.1

USER root
RUN apt-get update \
&& apt-get install -y --no-install-recommends \
build-essential libopenmpi-dev openssh-server openssh-client libsasl2-dev

RUN usermod -g 0 airflow
USER airflow

RUN pip install --user --upgrade pip
RUN pip install --user --no-cache-dir apache-airflow-upgrade-check

RUN pip install --user --no-cache-dir wheel setuptools --upgrade
RUN pip install --user --no-cache-dir "apache-airflow==${AIRFLOW_VERSION}" apache-airflow-providers-apache-hive==6.1.0
RUN pip install --user --no-cache-dir "apache-airflow==${AIRFLOW_VERSION}" apache-airflow-providers-apache-spark==4.1.0

