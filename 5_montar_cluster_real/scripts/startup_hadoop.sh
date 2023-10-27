#!/bin/bash

export HADOOP_HOME=/opt/hadoop
export PATH=$PATH:$HADOOP_HOME:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64/

echo "STARTING..." >> /tmp/log.txt;
function configMasterDatanodes(){
    hdfs namenode -format
    start-dfs.sh
}

function configGenericDatanodes(){
    mkdir -p /data/
    sed -e 's/{REPLICATION_NODES}/'${REPLICATION_NODES}'/g' $CONFIG_PATH/hdfs-site.xml.tpl > /opt/hadoop/etc/hadoop/hdfs-site.xml
    sed -e 's/{name}/fs.defaultFS/g' -e 's/{node}/nodo1/g'  $CONFIG_PATH/core-site.xml.tpl > /opt/hadoop/etc/hadoop/core-site.xml
    cp $CONFIG_PATH/mapred-site.xml.tpl /opt/hadoop/etc/hadoop/mapred-site.xml
    cp $CONFIG_PATH/yarn-site.xml.tpl /opt/hadoop/etc/hadoop/yarn-site.xml
    echo $WORKER_NODES | tr "," "\n" > /opt/hadoop/etc/hadoop/workers
}

sudo /etc/init.d/ssh start

mkdir /home/hadoop/.ssh/
ln -s /mnt/shared/authorized_keys /home/hadoop/.ssh/authorized_keys

SHARED_NODE_PATH=/mnt/shared/$NODE_NAME
mkdir -p $SHARED_NODE_PATH
CERTIFICATE=$SHARED_NODE_PATH/id_rsa

if [[ ! -f $CERTIFICATE ]]; then
    ssh-keygen -q -f $CERTIFICATE -N "" && cat $CERTIFICATE.pub >> /home/hadoop/.ssh/authorized_keys
fi

cp $CERTIFICATE /home/hadoop/.ssh/id_rsa
cp $CERTIFICATE.pub /home/hadoop/.ssh/id_rsa.pub

echo "CONFIG GENERIC NODE" >> /tmp/log.txt;
configGenericDatanodes;
if $SINGLE_NODE; then 
    echo "CONFIG IN SINGLE NODE" >> /tmp/log.txt;
    configMasterDatanodes;
else 
    echo "CONFIG IN MULTI NODE" >> /tmp/log.txt;
    if $IS_MASTER; then 
        echo "CONFIGURING MASTER NODE" >> /tmp/log.txt;
        configMasterDatanodes;
    else 
        echo "CONFIGURING SLAVE NODE" >> /tmp/log.txt;
    fi
fi





tail -f /dev/null