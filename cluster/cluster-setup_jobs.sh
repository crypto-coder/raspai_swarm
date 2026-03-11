#!/bin/bash

if [ $# > 0 ]; then
    if [ "$1" = "buildLifeboat" ]; then 
        echo " - Building a lifeboat"

        # build the lifeboat Docker image and push it to the registry
        docker buildx build --platform linux/arm64 --progress plain -t "registry.cc.local/coincatcher/lifeboat:latest" --file "./lifeboat.Dockerfile" . --push
    fi

    echo " - Setting up NFS as the default storage provider for the cluster"

    # install the nfs-subdir-external-provisioner using Helm
    helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
    helm install nfs-subdir-external-provisioner/nfs-subdir-external-provisioner --set nfs.server=c01w02 --set nfs.path=/storage

    # make the NFS storage class the default
    kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
    kubectl patch storageclass nfs-client -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
    
    echo " - Deploying jobs to sync AI models between all agents"

    # make sure the nfs PV + PVC are deployed
    kubectl apply -f ./nfs_pv+pvc.yml
    
    # setup the maintenance jobs in Kubernetes
    #kubectl apply -f ./rsync-cronjobs.yml
fi


