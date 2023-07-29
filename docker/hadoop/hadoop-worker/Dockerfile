FROM hadoop-base:latest

COPY start-worker.sh start-worker.sh

RUN chmod +x start-worker.sh

ENV HDFS_CONF_DFS_DATANODE_DATA_DIR=file:///hadoop/hdfs/data
RUN mkdir -p /hadoop/hdfs/data

EXPOSE 9864
EXPOSE 8042

# Adding dependencies for PySpark
RUN apt-get install -y curl python3.7 python3.7-dev python3.7-distutils
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.7 1
RUN update-alternatives --set python /usr/bin/python3.7
RUN curl https://bootstrap.pypa.io/get-pip.py | python3
RUN pip install --upgrade "pip==20.2.4"
RUN apt-get install -yqq python3-numpy python3-matplotlib python3-scipy python3-pandas python3-simpy

CMD [ "./start-worker.sh" ]