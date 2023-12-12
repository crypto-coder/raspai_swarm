#!/bin/bash

if [ $# > 0 ]; then
    if [ "$1" = "buildLifeboat" ]; then 
        echo " - Building a lifeboat"

        # build the lifeboat Docker image and push it to the registry
        docker buildx build --platform linux/arm64 --progress plain -t "registry.cc.local/coincatcher/lifeboat:latest" --file "./lifeboat.Dockerfile" . --push
    fi

    echo " - Deploying jobs to sync AI models between all agents"

    # make sure the nfs PV + PVC are deployed
    kubectl apply -f ./nfs_pv+pvc.yml
    
    # setup the maintenance jobs in Kubernetes
    kubectl apply -f ./rsync-cronjobs.yml
fi


