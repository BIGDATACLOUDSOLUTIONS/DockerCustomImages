#!/bin/bash
#This is a worker node on which NodeManager and DataNode Services will run

#Start NodeManager
nohup $HADOOP_HOME/bin/yarn --config $HADOOP_CONF_DIR nodemanager > nodemanager.log &

# Start DataNode Services
DATA_DIR=`echo $HDFS_CONF_DFS_DATANODE_DATA_DIR | perl -pe 's#file://##'`

if [ ! -d $DATA_DIR ]; then
    echo "Datanode data directory not found: $DATA_DIR"
    exit 2
fi

$HADOOP_HOME/bin/hdfs --config $HADOOP_CONF_DIR datanode
