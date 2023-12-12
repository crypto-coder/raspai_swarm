#!/bin/bash


declare -a NODES=("c01w01" "c01w02" "c01w03" "c01w04" "c01w05" "c01w06" "c01w07" "c01w08" "c01w09" "c01w10" "c01w11" "c01w12")


addURL() {
    URL=$1
    IP_ADDRESS=$2

    addURLToLocal $URL $IP_ADDRESS
    addURLToAllClusterNodes $URL $IP_ADDRESS
}

addURLToLocal() {
    URL=$1
    IP_ADDRESS=$2

    sudo sed -i "/$URL/d" /etc/hosts
    echo "$IP_ADDRESS       $URL" | sudo tee -a /etc/hosts

    echo "Added locally : $IP_ADDRESS --> $URL"
}

addURLToAllClusterNodes() {
    URL=$1
    IP_ADDRESS=$2

    for NODE in "${NODES[@]}"
    do
        addURLToClusterNode $NODE $URL $IP_ADDRESS
    done
}

addURLToClusterNode() {
    NODE=$1
    URL=$2
    IP_ADDRESS=$3

    REMOTE_COMMAND='sudo sed -i "/'$URL'/d" /etc/hosts'
    ssh clusteradm@$NODE eval $REMOTE_COMMAND

    REMOTE_COMMAND='echo "'$IP_ADDRESS'       '$URL'" | sudo tee -a /etc/hosts'
    ssh clusteradm@$NODE eval $REMOTE_COMMAND

    echo "Added $NODE : $IP_ADDRESS --> $URL"
}

addURLToLocal c01w01 10.0.1.10
addURLToLocal c01w02 10.0.1.11
addURLToLocal c01w03 10.0.1.12
addURLToLocal c01w04 10.0.1.13
addURLToLocal c01w05 10.0.1.14
addURLToLocal c01w06 10.0.1.15
addURLToLocal c01w07 10.0.1.16
addURLToLocal c01w08 10.0.1.17
addURLToLocal c01w09 10.0.1.18
addURLToLocal c01w10 10.0.1.19
addURLToLocal c01w11 10.0.1.20
addURLToLocal c01w12 10.0.1.21

addURLToAllClusterNodes c01w01 10.0.1.10
addURLToAllClusterNodes c01w02 10.0.1.11
addURLToAllClusterNodes c01w03 10.0.1.12
addURLToAllClusterNodes c01w04 10.0.1.13
addURLToAllClusterNodes c01w05 10.0.1.14
addURLToAllClusterNodes c01w06 10.0.1.15
addURLToAllClusterNodes c01w07 10.0.1.16
addURLToAllClusterNodes c01w08 10.0.1.17
addURLToAllClusterNodes c01w09 10.0.1.18
addURLToAllClusterNodes c01w10 10.0.1.19
addURLToAllClusterNodes c01w11 10.0.1.20
addURLToAllClusterNodes c01w12 10.0.1.21

addURL registry.cc.local 10.0.1.10

addURLToLocal aiagent01.cc.local 10.0.1.10
addURLToLocal aiagent02.cc.local 10.0.1.10
addURLToLocal aiagent03.cc.local 10.0.1.10
addURLToLocal aiagent04.cc.local 10.0.1.10



cat /etc/hosts