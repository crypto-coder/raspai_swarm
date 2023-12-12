#!/bin/bash


# Only apply the MEMLOCK fix to the agent-compute nodes, so they can fully lock AI models in memory
declare -a NODES=("c01w08" "c01w10" "c01w11" "c01w12")

fixMEMLOCK() {
    for NODE in "${NODES[@]}"
    do
        echo "----- Start fixing MEMLOCK on $NODE"
        fixMEMLOCKOnClusterNode $NODE
    done
}

fixMEMLOCKOnClusterNode() {
    NODE=$1

    REMOTE_COMMAND="sudo sed -i 's/#DefaultLimitMEMLOCK=/DefaultLimitMEMLOCK=7623566950/' /etc/systemd/system.conf"
    ssh clusteradm@$NODE eval $REMOTE_COMMAND

    REMOTE_COMMAND="sudo sed -i 's/#DefaultLimitMEMLOCK=/DefaultLimitMEMLOCK=7623566950/' /etc/systemd/user.conf"
    ssh clusteradm@$NODE eval $REMOTE_COMMAND

    HAS_HARD_LIMIT=$(ssh clusteradm@c01w08 eval "grep -c '^root\ hard\ memlock' /etc/security/limits.conf")
    if [ "$HAS_HARD_LIMIT" -eq "0" ]; then
        REMOTE_COMMAND='sudo sed -i "`wc -l < /etc/security/limits.conf`i\\\root hard memlock 7400032\\" /etc/security/limits.conf'
        ssh clusteradm@$NODE eval $REMOTE_COMMAND
    fi
        
    HAS_SOFT_LIMIT=$(ssh clusteradm@c01w08 eval "grep -c '^root\ soft\ memlock' /etc/security/limits.conf")
    if [ "$HAS_SOFT_LIMIT" -eq "0" ]; then
        REMOTE_COMMAND='sudo sed -i "`wc -l < /etc/security/limits.conf`i\\\root soft memlock 7400032\\" /etc/security/limits.conf'
        ssh clusteradm@$NODE eval $REMOTE_COMMAND
    fi

    ssh clusteradm@$NODE sudo shutdown -r now

    echo "----- Finished fixing MEMLOCK on $NODE"
}


fixMEMLOCK
