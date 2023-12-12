#!/bin/bash


declare -a NODES=("c01w01" "c01w02" "c01w03" "c01w04" "c01w05" "c01w06" "c01w07" "c01w08" "c01w09" "c01w10" "c01w11" "c01w12")


fixNFS() {
    for NODE in "${NODES[@]}"
    do
        fixNFSOnClusterNode $NODE
    done
}

fixNFSOnClusterNode() {
    NODE=$1

    REMOTE_COMMAND='sudo sed -i "s/no_subtree_check\)/no_subtree_check,anonuid=1000,anongid=1000\)/" /etc/exports'
    ssh clusteradm@$NODE eval $REMOTE_COMMAND
    ssh clusteradm@$NODE -- sudo chown clusteradm:clusteradm -R /storage
    ssh clusteradm@$NODE -- sudo exportfs -vr

    echo "----- Fixed NFS on $NODE"
}


fixNFS