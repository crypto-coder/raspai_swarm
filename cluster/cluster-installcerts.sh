#!/bin/bash

export CERT_STORE="./certs"
declare -a NODES=("c01w01" "c01w02" "c01w03" "c01w04" "c01w05" "c01w06" "c01w07" "c01w08" "c01w09" "c01w10" "c01w11" "c01w12")


createSelfSignedCert() {
    CN=$1

    addCNtoHosts $CN

    if [ ! -d "$CERT_STORE/ca" ]; then
        echo " - Creating the 'ca' folder and CA key / certificate"
        mkdir -p $CERT_STORE/ca
        openssl genrsa -out $CERT_STORE/ca/ca.key 2048
        openssl req -x509 -new -nodes -key $CERT_STORE/ca/ca.key -subj "/CN=10.0.1.10" -days 3650 -out $CERT_STORE/ca/ca.crt
        sudo cp $CERT_STORE/ca/ca.crt /usr/local/share/ca-certificates/
        sudo update-ca-certificates
        sudo systemctl restart docker

        addCACertToClusterNodes
    fi
    
    # Create a folder if it is missing
    if [ ! -d "$CERT_STORE/$CN" ]; then
        echo " - Creating the '$CN' folder"
        mkdir -p $CERT_STORE/$CN
    fi

    # Create a server key if it is missing
    if [ ! -f $CERT_STORE/$CN/server.key ]; then
        echo " - Generating server key"
        openssl genrsa -out $CERT_STORE/$CN/server.key 2048
    fi

    # Create a self-signed CSR, if it is missing
    if [ ! -f $CERT_STORE/$CN/csr.conf ]; then
        echo " - Generating CSR"
        createCSR $CN
    fi

    # Create a self-signed cert, if it is missing
    if [ ! -f $CERT_STORE/$CN/server.crt ]; then
        echo " - Generating server certificate"
        openssl x509 -req -in $CERT_STORE/$CN/server.csr -CA $CERT_STORE/ca/ca.crt -CAkey $CERT_STORE/ca/ca.key \
                    -CAcreateserial -out $CERT_STORE/$CN/server.crt -days 10000 \
                    -extensions v3_ext -extfile $CERT_STORE/$CN/csr.conf
    fi

    loadCertInKubernetes $CN
}


addCACertToClusterNodes() {
    for NODE in "${NODES[@]}"
    do
        echo "add CA Cert to Node - $NODE"
        addCACertToClusterNode $NODE
    done    
}

addCACertToClusterNode() {
    NODE=$1

    scp $CERT_STORE/ca/ca.crt clusteradm@$NODE:/home/clusteradm/    
    REMOTE_COMMAND='sudo cp -u /home/clusteradm/ca.crt /usr/local/share/ca-certificates/'
    ssh clusteradm@$NODE eval $REMOTE_COMMAND    
    ssh clusteradm@$NODE -- sudo update-ca-certificates
}


createCSR() {
    CN=$1
    cat > $CERT_STORE/$CN/csr.conf <<EOL
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[ dn ]
C = US
ST = FL
L = Orlando
O = CoinCatcher
OU = Development
CN = ${CN}

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster
DNS.5 = kubernetes.default.svc.cluster.local
DNS.6 = ${CN}
IP.1 = 10.0.1.10

[ v3_ext ]
authorityKeyIdentifier=keyid,issuer:always
basicConstraints=CA:FALSE
keyUsage=keyEncipherment,dataEncipherment
extendedKeyUsage=serverAuth,clientAuth
subjectAltName=@alt_names
EOL

    openssl req -new -key $CERT_STORE/$CN/server.key -out $CERT_STORE/$CN/server.csr -config $CERT_STORE/$CN/csr.conf
}

addCNtoHosts() {
    CN=$1

    echo " - Adding $CN to /etc/hosts"
    sudo sed -i "/$CN/d" /etc/hosts
    echo "10.0.1.10       $CN" | sudo tee -a /etc/hosts
}

loadCertInKubernetes() {
    CN=$1    
    CERT_STRING=$(base64 -w0 $CERT_STORE/$CN/server.crt)
    KEY_STRING=$(base64 -w0 $CERT_STORE/$CN/server.key)

    if [ -f $CERT_STORE/$CN/secret.yml ]; then
        echo " - Deleting old Kubernetes secret file"
        rm $CERT_STORE/$CN/secret.yml
    fi

    SECRET_EXISTS=$(kubectl get secret | grep -c ${CN}-tls)
    if [ "$SECRET_EXISTS" = "1" ]; then
        echo " - Secret exists in Kubnetes...deleting it"
    fi

    cat > $CERT_STORE/$CN/secret.yml <<EOL
apiVersion: v1
kind: Secret
metadata:
  name: ${CN}-tls
  namespace: default
data:
  tls.crt: |
    ${CERT_STRING}
  tls.key: |
    ${KEY_STRING}
type: kubernetes.io/tls
EOL

    echo " - Installing secret in Kubernetes for $CN"
    kubectl apply -f $CERT_STORE/$CN/secret.yml
}



createSelfSignedCert registry.cc.local