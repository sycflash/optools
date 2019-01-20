#!/bin/bash

# 安装kafka集群到一个主机上

# 部署zk
install_zk(){
    yum -y install java
    cd /tmp/ && curl -L -O http://apache.fayea.com/zookeeper/stable/zookeeper-3.4.12.tar.gz
    mkdir -p /usr/local/eqmore/ && tar zxvf zookeeper-3.4.12.tar.gz -C /usr/local/eqmore/
    ZK_CLUSTER_INSTALL_PATH=/usr/local/eqmore/zk-one-cluster
    mkdir -p $ZK_CLUSTER_INSTALL_PATH
    for i in {1..3}
    do
        ZK_CONF_PATH=$ZK_CLUSTER_INSTALL_PATH/zk${i}/conf/zoo.cfg
        cp -pr /usr/local/eqmore/zookeeper-3.4.12 $ZK_CLUSTER_INSTALL_PATH/zk${i}
        mkdir -p /data/zk${i}/{data,log}
        echo ${i} > /data/zk${i}/data/myid
        cp /usr/local/eqmore/zookeeper-3.4.12/conf/zoo_sample.cfg $ZK_CONF_PATH
        sed -i "s/dataLogDir=.*$//g" $ZK_CONF_PATH
        sed -i "s/clientPort=.*$/clientPort=${i}2181/g" $ZK_CONF_PATH
        sed -i "s/dataDir=.*$/dataDir=\/data\/zk${i}\/data/g" $ZK_CONF_PATH
        sed -i "s/server\.\d.*$//g" $ZK_CONF_PATH
        echo "dataLogDir=/data/zk${i}/log/" >> $ZK_CONF_PATH
        echo "server.1=0.0.0.0:12888:13888" >> $ZK_CONF_PATH
        echo "server.2=0.0.0.0:22888:23888" >> $ZK_CONF_PATH
        echo "server.3=0.0.0.0:32888:33888" >> $ZK_CONF_PATH
        cd $ZK_CLUSTER_INSTALL_PATH/zk${i}/bin/ && ./zkServer.sh start
    done
}

install_kafka(){
    cd /tmp/ && curl -L -O https://mirrors.cnnic.cn/apache/kafka/2.1.0/kafka_2.11-2.1.0.tgz
    tar zxf kafka_2.11-2.1.0.tgz -C /usr/local/eqmore
    cd /usr/local/eqmore/kafka_2.11-2.1.0/
    KAFKA_CLUSTER_INSTALL_PATH=/usr/local/eqmore/kafka_one_cluster
    for i in {1..3}
    do
        cp -pr /usr/local/eqmore/kafka_2.11-2.1.0/ $KAFKA_CLUSTER_INSTALL_PATH/kafka-server-0${i}
        cd $KAFKA_CLUSTER_INSTALL_PATH/kafka-server-0${i}/config 
        cp server.properties server.properties.bak
        sed -i "s/broker\.id=.*/broker\.id=${i}/g" server.properties
        sed -i "s/port=.*/port=${i}9092/g" server.properties
        sed -i "s/advertised.port=.*/advertised.port=${i}9092/g" server.properties
        sed -i "s/zookeeper.connect=.*$/zookeeper.connect=127.0.0.1:12181,127.0.0.1:22181,127.0.0.1:32181/g" server.properties
        sed -i "s/default.replication.factor=.*/default.replication.factor=2/g" server.properties

        cd $KAFKA_CLUSTER_INSTALL_PATH/kafka-server-0${i}/bin/
        ./kafka-server-start.sh -daemon ../config/server.properties
    done
    
}
install_zk
install_kafka