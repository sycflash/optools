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
        sed -i 's/dataDir=.*$/dataDir=/data/zk${i}/data/g' $ZK_CONF_PATH
        sed -i 's/dataLogDir=.*$/dataLogDir=/data/zk${i}/log/g' $ZK_CONF_PATH
        sed -i 's/clientPort=.*$/clientPort=${i}2181/g' $ZK_CONF_PATH
        sed -i 's/server\.\d.*$//g' $ZK_CONF_PATH
        echo "server.1=0.0.0.0:12888:13888" >> $ZK_CONF_PATH
        echo "server.2=0.0.0.0:22888:23888" >> $ZK_CONF_PATH
        echo "server.3=0.0.0.0:32888:33888" >> $ZK_CONF_PATH
        cd $ZK_CLUSTER_INSTALL_PATH/zk${i}/bin/ && ./zkServer.sh start
    done
}

install_zk