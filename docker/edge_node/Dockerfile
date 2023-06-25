FROM ubuntu:latest
LABEL authors="RAJESH"

USER root

#Install Build tools
RUN apt-get update \
&& apt-get install -y --no-install-recommends build-essential libopenmpi-dev openssh-server openssh-client libsasl2-dev

#Install Java 8
RUN echo "y" | apt install openjdk-8-jdk

# Define commonly used JAVA_HOME variable
RUN export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux
ENV ACCEPT_EULA=Y


#Download and Install Hadoop
ENV HADOOP_VERSION=3.1.1
ENV HADOOP_HOME=/opt/hadoop
ENV HADOOP_CONF_DIR=/etc/hadoop
ENV USER=root
ENV PATH ${HADOOP_HOME}/bin/:$PATH

RUN apt-get update -yqq && \
    apt-get upgrade -yqq && \
    apt-get install -yqq --no-install-recommends \
    apt-utils \
    curl \
    wget \
    netcat && \
    apt-get autoremove -yqq --purge

RUN mkdir -p /opt/hadoop

RUN wget -c -O hadoop.tar.gz https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz && \
    tar xvf hadoop.tar.gz --directory=/opt/hadoop --exclude=hadoop-${HADOOP_VERSION}/share/doc --strip 1 && \
    rm -rf hadoop.tar.gz && \
    ln -s /opt/hadoop/etc/hadoop /etc/hadoop && \
    mkdir /opt/hadoop/logs && \
    mkdir /hadoop-data

COPY ./conf/hadoop ./conf

RUN mv ./conf/* /etc/hadoop/ && \
    rm -rf ./conf

RUN rm -rf /opt/hadoop/share/hadoop/common/lib/slf4j-log4j*.jar

#Download and Install Hive
ARG HIVE_VERSION
ENV HIVE_VERSION=${HIVE_VERSION:-3.1.2}
ENV HIVE_HOME=/opt/hive
ENV PATH=${HIVE_HOME}/bin:$PATH

WORKDIR /opt

RUN apt-get install -yqq \
    wget \
    procps && \
    wget -c -O hive.tar.gz https://archive.apache.org/dist/hive/hive-${HIVE_VERSION}/apache-hive-${HIVE_VERSION}-bin.tar.gz && \
    tar xvf hive.tar.gz && \
    rm hive.tar.gz && \
    mv apache-hive-${HIVE_VERSION}-bin hive && \
    wget -O ${HIVE_HOME}/lib/postgresql-jdbc.jar https://jdbc.postgresql.org/download/postgresql-42.2.14.jar && \
    apt-get --purge remove -yqq wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Spark should be compiled with Hive to be able to use it
# hive-site.xml should be copied to $SPARK_HOME/conf folder
COPY ./conf/hive/hive-site.xml ${HIVE_HOME}/conf
COPY ./conf/hive/hive-env.sh ${HIVE_HOME}/conf
COPY ./conf/hive/ivysettings.xml ${HIVE_HOME}/conf

