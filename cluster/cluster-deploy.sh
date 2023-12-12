#!/bin/bash


mkdir ~/.kube


deployBlade() {
    TYPE=$1
    CLUSTER_MASTER_IP_ADDRESS=$2
    CLUSTER_NAME=$2
    IP_ADDRESS=$3

    if [ "$TYPE" = "cluster-master" ]; then
        #k3sup install --ip $IP_ADDRESS --user clusteradm --local-path $HOME/.kube/config --cluster --context $CLUSTER_NAME --k3s-channel stable --k3s-extra-args '--disable=traefik --disable=servicelb'
        k3sup install --ip $IP_ADDRESS --user clusteradm --local-path $HOME/.kube/config --cluster --context $CLUSTER_NAME --k3s-channel stable
        sleep 150s
    elif [ "$TYPE" = "ha-master" ]; then
        #k3sup join --ip $IP_ADDRESS --user clusteradm --server-user clusteradm --server-ip $CLUSTER_MASTER_IP_ADDRESS --server --k3s-channel stable --k3s-extra-args '--disable=traefik --disable=servicelb'
        k3sup join --ip $IP_ADDRESS --user clusteradm --server-user clusteradm --server-ip $CLUSTER_MASTER_IP_ADDRESS --server --k3s-channel stable
        sleep 150s
    else
        #k3sup join --ip $IP_ADDRESS --server-ip $CLUSTER_MASTER_IP_ADDRESS --user clusteradm --k3s-channel stable --k3s-extra-args '--disable=traefik --disable=servicelb'
        k3sup join --ip $IP_ADDRESS --server-ip $CLUSTER_MASTER_IP_ADDRESS --user clusteradm --server-user clusteradm
    fi

    # Check if we are attempting to format the /dev/sda device
    if [[ $# > 3 ]]; then
        FORMAT_SDA=$(echo $4 | grep -c 'formatSDA')	
        
        if [[ "$FORMAT_SDA" -eq "1" ]]; then
            #formatSDA $IP_ADDRESS
            echo "SDA formatting disabled"
        fi
    fi

}

fixUbuntu22() {
    ssh clusteradm@$IP_ADDRESS -- sudo apt install -y linux-modules-extra-raspi
}

formatSDA() {
    IP_ADDRESS=$1
    SDA_IS_PARTITIONED=$(ssh clusteradm@$IP_ADDRESS -- sudo parted /dev/sda print | grep -c storage)
    if [ "$SDA_IS_PARTITIONED" -eq "0" ]; then
        echo "------ Formatting SDA on "$IP_ADDRESS
        OPTIMAL_IO_SIZE=$(ssh clusteradm@$IP_ADDRESS -- cat /sys/block/sda/queue/optimal_io_size | tr -d '\r')
        ALIGNMENT_OFFSET=$(ssh clusteradm@$IP_ADDRESS -- cat /sys/block/sda/alignment_offset | tr -d '\r')
        PHYSICAL_BLOCK_SIZE=$(ssh clusteradm@$IP_ADDRESS -- cat /sys/block/sda/queue/physical_block_size | tr -d '\r')
        START_SECTOR=$(((ALIGNMENT_OFFSET + OPTIMAL_IO_SIZE) / PHYSICAL_BLOCK_SIZE))

        ssh clusteradm@$IP_ADDRESS -- sudo parted /dev/sda mklabel gpt

        REMOTE_COMMAND="sudo parted /dev/sda mkpart storage ext4 "$START_SECTOR"s 100%"
        ssh clusteradm@$IP_ADDRESS eval $REMOTE_COMMAND
        ssh clusteradm@$IP_ADDRESS -- sudo mkfs.ext4 /dev/sda1
        ssh clusteradm@$IP_ADDRESS -- sudo mount -a
    fi
}






# SETUP THE CLUSTER MASTER
deployBlade cluster-master c1 10.0.1.10
kubectl ctx c1

# SETUP HA MASTER (2 more nodes)
deployBlade ha-master 10.0.1.10 10.0.1.11
deployBlade ha-master 10.0.1.10 10.0.1.12

# SETUP K3S WORKER NODE
deployBlade worker 10.0.1.10 10.0.1.13
deployBlade worker 10.0.1.10 10.0.1.14
deployBlade worker 10.0.1.10 10.0.1.15
deployBlade worker 10.0.1.10 10.0.1.16
deployBlade worker 10.0.1.10 10.0.1.17
deployBlade worker 10.0.1.10 10.0.1.18
deployBlade worker 10.0.1.10 10.0.1.19
deployBlade worker 10.0.1.10 10.0.1.20
deployBlade worker 10.0.1.10 10.0.1.21