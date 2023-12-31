FROM airflow-base:2.6.1

USER root

ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux
ENV ACCEPT_EULA=Y

RUN apt-get update -yqq && \
    apt-get upgrade -yqq && \
    apt-get install -yqq --no-install-recommends \
    apt-utils \
    curl \
    wget \
    netcat && \
    apt-get autoremove -yqq --purge

# Install JDK8
# Download from https://download.bell-sw.com/java/8u372+7/bellsoft-jdk8u372+7-linux-amd64.tar.gz
RUN wget -c -O jdk8u372amd64.tar.gz https://download.bell-sw.com/java/8u372+7/bellsoft-jdk8u372+7-linux-amd64.tar.gz
#COPY ./jdk8u372amd64.tar.gz jdk8u372amd64.tar.gz
RUN mkdir /usr/lib/jvm/
RUN tar xvf jdk8u372amd64.tar.gz --directory=/usr/lib/jvm/
ENV JAVA_HOME="/usr/lib/jvm/jdk8u372"
ENV PATH=${JAVA_HOME}/bin/:$PATH

#Download and Install Hadoop
ENV HADOOP_VERSION=3.2.4
ENV HADOOP_HOME=/opt/hadoop
ENV HADOOP_CONF_DIR=/etc/hadoop
ENV USER=root
ENV PATH ${HADOOP_HOME}/bin/:$PATH

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

RUN mv ${HIVE_HOME}/lib/guava-19.0.jar ${HIVE_HOME}/lib/guava-19.0.jar.bak
RUN cp ${HADOOP_HOME}/share/hadoop/hdfs/lib/guava-27.0-jre.jar ${HIVE_HOME}/lib/


# Defining useful environment variables
ENV SPARK_VERSION=3.2.1
ENV HADOOP_VERSION=3.2
ENV SCALA_VERSION=2.12.4
ENV SCALA_HOME=/usr/share/scala
ENV SPARK_HOME=/usr/local/spark
ENV SBT_VERSION=1.2.8
ENV SBT_HOME=/usr/local/sbt
ENV PYTHONHASHSEED=1
ENV SPARK_EXECUTOR_MEMORY=650m
ENV SPARK_DRIVER_MEMORY=650m
ENV SPARK_WORKER_MEMORY=650m
ENV SPARK_DAEMON_MEMORY=650m
ENV PATH $SBT_HOME/bin/:$PATH
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

RUN wget https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz
RUN tar zxf spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz && \
    mv spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}/* . && \
    rm -rf spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz && \
    rm -rf spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}

# Use Spark with Hive
RUN cp ${HIVE_HOME}/conf/hive-site.xml $SPARK_HOME/conf

# Adding dependencies for PySpark
RUN apt-get update -yqq
RUN curl https://bootstrap.pypa.io/get-pip.py | python3
RUN apt-get install -yqq python3-numpy python3-pandas

RUN apt-get autoremove -yqq --purge && \
    apt-get clean && \
    rm -rf /tmp/* /var/tmp/*


RUN usermod -g 0 airflow
USER airflow

WORKDIR $AIRFLOW_HOME