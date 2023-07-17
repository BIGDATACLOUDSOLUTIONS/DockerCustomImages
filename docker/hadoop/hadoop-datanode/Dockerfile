FROM hadoop-base:latest

ENV HDFS_CONF_DFS_DATANODE_DATA_DIR=file:///hadoop/hdfs/data

RUN mkdir -p /hadoop/hdfs/data

COPY start-datanode.sh start-datanode.sh

RUN chmod +x start-datanode.sh

EXPOSE 9864

CMD [ "./start-datanode.sh" ]