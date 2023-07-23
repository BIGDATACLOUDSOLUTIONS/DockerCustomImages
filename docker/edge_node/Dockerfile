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
ENV HADOOP_VERSION=3.2.4
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


# Defining useful environment variables
ENV SPARK_VERSION=3.2.1
ENV HADOOP_VERSION=3.2
ENV SCALA_VERSION=2.12.4
ENV SCALA_HOME=/usr/share/scala
ENV SPARK_HOME=/usr/local/spark
ENV SBT_VERSION=1.2.8
ENV PYTHONHASHSEED=1
ENV SPARK_EXECUTOR_MEMORY=650m
ENV SPARK_DRIVER_MEMORY=650m
ENV SPARK_WORKER_MEMORY=650m
ENV SPARK_DAEMON_MEMORY=650m
ENV PATH $SPARK_HOME/bin/:$PATH

# Upgrade and install some tools and dependencies
RUN apt-get update -yqq && \
    apt-get upgrade -yqq && \
    apt-get install -yqq \
    netcat \
    apt-utils \
    curl \
    vim \
    ssh \
    net-tools \
    ca-certificates \
    jq \
    wget \
    software-properties-common

# Installing Scala
WORKDIR /tmp

RUN wget --no-verbose "https://downloads.typesafe.com/scala/${SCALA_VERSION}/scala-${SCALA_VERSION}.tgz"
RUN tar zxf scala-${SCALA_VERSION}.tgz && \
    mkdir ${SCALA_HOME} && \
    rm "scala-${SCALA_VERSION}/bin/"*.bat && \
    mv "scala-${SCALA_VERSION}/bin" "scala-${SCALA_VERSION}/lib" "${SCALA_HOME}" && \
    ln -s "${SCALA_HOME}/bin/*" "/usr/bin/" && \
    rm -rf *

# Installing SBT
RUN export PATH="/usr/local/sbt/bin:$PATH" && \
    apt-get update && \
    apt-get install ca-certificates wget tar && \
    mkdir -p "/usr/local/sbt" && \
    wget -qO - --no-check-certificate "https://github.com/sbt/sbt/releases/download/v${SBT_VERSION}/sbt-${SBT_VERSION}.tgz" | tar xz -C /usr/local/sbt --strip-components=1 && \
    sbt sbtVersion


# Installing Spark
WORKDIR ${SPARK_HOME}

RUN wget --no-verbose https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz
RUN tar zxf spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz && \
    mv spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}/* . && \
    rm -rf spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz && \
    rm -rf spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}

# Use Spark with Hive
RUN cp ${HIVE_HOME}/conf/hive-site.xml $SPARK_HOME/conf

RUN apt-get autoremove -yqq --purge && \
    apt-get clean && \
    rm -rf /tmp/* /var/tmp/*


#Install Python Packages
RUN curl https://bootstrap.pypa.io/get-pip.py | python3
RUN pip install --upgrade pip
RUN apt-get install -yqq python3-numpy python3-pandas


WORKDIR /data