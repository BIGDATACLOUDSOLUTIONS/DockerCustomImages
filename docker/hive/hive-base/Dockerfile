FROM hadoop-base:latest

ARG HIVE_VERSION
ENV HIVE_VERSION=${HIVE_VERSION:-3.1.2}
ENV HIVE_HOME=/opt/hive
ENV PATH=${HIVE_HOME}/bin:$PATH

WORKDIR /opt

RUN apt-get install -yqq \
    wget \
    procps

# For fast build, download and keep file with Dockerfile
# else comment COPY command and uncomment RUN wget.. command
#COPY ./apache-hive-3.1.2-bin.tar.gz hive.tar.gz
RUN wget -c -O hive.tar.gz https://archive.apache.org/dist/hive/hive-${HIVE_VERSION}/apache-hive-${HIVE_VERSION}-bin.tar.gz

RUN tar xvf hive.tar.gz && \
    rm hive.tar.gz && \
    mv apache-hive-${HIVE_VERSION}-bin hive && \
    wget -O ${HIVE_HOME}/lib/postgresql-jdbc.jar https://jdbc.postgresql.org/download/postgresql-42.2.14.jar && \
    apt-get --purge remove -yqq wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Spark should be compiled with Hive to be able to use it
# hive-site.xml should be copied to $SPARK_HOME/conf folder

COPY ./conf/hive-site.xml ${HIVE_HOME}/conf
COPY ./conf/hive-env.sh ${HIVE_HOME}/conf
COPY ./conf/ivysettings.xml ${HIVE_HOME}/conf

# Help: http://www.mtitek.com/tutorials/bigdata/hive/install.php
RUN mv ${HIVE_HOME}/lib/guava-19.0.jar ${HIVE_HOME}/lib/guava-19.0.jar.bak
RUN cp ${HADOOP_HOME}/share/hadoop/hdfs/lib/guava-27.0-jre.jar ${HIVE_HOME}/lib/

COPY ./entrypoint.sh .
RUN chmod +x entrypoint.sh

EXPOSE 10000 
EXPOSE 10001
EXPOSE 10002

ENTRYPOINT [ "./entrypoint.sh" ]