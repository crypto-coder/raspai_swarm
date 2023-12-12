
## Overview

Pre-requisites for setting up the cluster.  This will mostly consist of installing application locally on your development environment, and applying some configurations for those applications. 

## Install tools for managing Kubernetes

Kubectl
``` 
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"

chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
```

Krew
```
(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  KREW="krew-${OS}_${ARCH}" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
  tar zxvf "${KREW}.tar.gz" &&
  ./"${KREW}" install krew
)

export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
echo 'export PATH="'${KREW_ROOT:-$HOME/.krew}'/bin:'$PATH'"' | sudo tee -a ~/.bashrc
```

KubeCTX, KubeNS, NGINX Ingress, FlameGraphs, KubeGraph, KTop, Certificate Manager
```
kubectl krew install ctx
kubectl krew install ns
kubectl krew install ingress-nginx
kubectl krew install flame
kubectl krew install graph
kubectl krew install ktop
kubectl krew install view-utilization
kubectl krew install cert-manager
```

K3sup
```
curl -sLS https://get.k3sup.dev | sh
sudo cp k3sup /usr/local/bin/k3sup
```

Arkade, Helm, FaaS-CLI
```
curl -sLS https://get.arkade.dev | sudo sh
ark get helm
ark get faas-cli
echo "export PATH=$PATH:$HOME/.arkade/bin/" | tee -a ~/.bashrc
```

## Add DNS entries to local /etc/hosts
We are using the URL `cc.local` to refer to our cluster throughout this repo.  Change based on your naming scheme
```
sudo nano /etc/hosts
10.0.1.10     cc.local
10.0.1.10     c01.cc.local
10.0.1.10     monitor.cc.local
10.0.1.10     prometheus.cc.local
10.0.1.10     registry.cc.local
```

## Create a local Docker 'crossbuild' environment
This build is done on an x86 computer using a docker crossbuild.  We will build docker images for both `linux/amd64` and `linux/arm64`.  Because we are using a docker container to do the crossbuild, we will not be able to store the build output in the local `docker images` catalog.  So we need to `--push` the build output to a private docker registry.  We will install this private docker registry in Kubernetes using Helm in a later step.  See [cluster README](cluster/README.md) for details about installing a private docker registry.

```
# make sure docker is installed and running
sudo systemctl status docker

# if docker is not installed, install it
sudo apt update
sudo apt install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install docker-ce

# make sure the docker command is available
docker ps -a

# check for existing context
docker context ls

# check for existing builders
docker buildx 

# create a custom BuildKit config, that indicates we are using an insecure private docker registry
cat > ./buildkit.toml <<EOL
[registry."registry.cc.local"]
  insecure=true
EOL

# add a builder for linux/amd64 + linux/arm64
docker buildx create --name crossbuilder --driver docker-container --platform linux/amd64,linux/arm64 --config ./buildkit.toml --bootstrap --use
```