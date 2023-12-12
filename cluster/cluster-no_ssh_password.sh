#!/bin/bash


copyKey() {
    IP_ADDRESS=$1

    # Unlock ssh authorized_keys on the destination
    ssh clusteradm@$IP_ADDRESS -- sudo chown clusteradm:clusteradm -R /home/clusteradm/.ssh

    # Copy the SSH key
    ssh-copy-id clusteradm@$IP_ADDRESS

    # Lock the SSH authorized_keys
    ssh clusteradm@$IP_ADDRESS -- sudo chmod 600 /home/clusteradm/.ssh/authorized_keys
}






# SETUP THE CLUSTER MASTER
copyKey 10.0.1.10
copyKey 10.0.1.11
copyKey 10.0.1.12
copyKey 10.0.1.13
copyKey 10.0.1.14
copyKey 10.0.1.15
copyKey 10.0.1.16
copyKey 10.0.1.17
copyKey 10.0.1.18
copyKey 10.0.1.19
copyKey 10.0.1.20
copyKey 10.0.1.21