#!/bin/bash

#kubectl label nodes c01w04 kubernetes.io/role=worker
#kubectl label nodes c01w04 node-type=worker
#kubectl label nodes c01w05 kubernetes.io/role=worker
#kubectl label nodes c01w05 node-type=worker
#kubectl label nodes c01w05 ai-unit=agent1-memory
#kubectl label nodes c01w06 kubernetes.io/role=worker
#kubectl label nodes c01w06 node-type=worker
#kubectl label nodes c01w06 ai-unit=agent1-compute
#kubectl label nodes c01w07 kubernetes.io/role=worker
#kubectl label nodes c01w07 node-type=worker
#kubectl label nodes c01w07 ai-unit=agent2-memory
#kubectl label nodes c01w08 kubernetes.io/role=worker
#kubectl label nodes c01w08 node-type=worker
#kubectl label nodes c01w08 ai-unit=agent2-compute
#kubectl label nodes c01w09 kubernetes.io/role=worker
#kubectl label nodes c01w09 node-type=worker
#kubectl label nodes c01w09 ai-unit=agent3-memory
#kubectl label nodes c01w10 kubernetes.io/role=worker
#kubectl label nodes c01w10 node-type=worker
#kubectl label nodes c01w10 ai-unit=agent3-compute
#kubectl label nodes c01w11 kubernetes.io/role=worker
#kubectl label nodes c01w11 node-type=worker
#kubectl label nodes c01w11 ai-unit=agent4-memory
#kubectl label nodes c01w12 kubernetes.io/role=worker
#kubectl label nodes c01w12 node-type=worker
#kubectl label nodes c01w12 ai-unit=agent4-compute


addLabels() {
    NODE_NAME=$1
    NODE_TYPE=$2

    # remove existing labels, then re-add them
    if [ "$NODE_TYPE" = "worker" ]; then
        kubectl label --overwrite nodes $NODE_NAME kubernetes.io/role-
        kubectl label --overwrite nodes $NODE_NAME node-type-

        kubectl label nodes $NODE_NAME kubernetes.io/role=worker
        kubectl label nodes $NODE_NAME node-type=worker
    fi

    # remove existing ai-unit labels, and re-add them
    kubectl label --overwrite nodes $NODE_NAME aiunit-
    if [ $# -gt 2 ]; then
        AI_UNIT_TYPE=$3

        kubectl label nodes $NODE_NAME aiunit=$AI_UNIT_TYPE
    fi
}


addLabels c01w04 worker agent1memory
addLabels c01w05 worker agent2memory
addLabels c01w06 worker agent3memory
addLabels c01w07 worker swarmstorage
addLabels c01w08 worker agent1compute
addLabels c01w09 worker agent4memory
addLabels c01w10 worker agent2compute
addLabels c01w11 worker agent3compute
addLabels c01w12 worker agent4compute