#!/bin/bash

ssh clusteradm@10.0.1.21 /usr/local/bin/k3s-agent-uninstall.sh
ssh clusteradm@10.0.1.20 /usr/local/bin/k3s-agent-uninstall.sh
ssh clusteradm@10.0.1.19 /usr/local/bin/k3s-agent-uninstall.sh
ssh clusteradm@10.0.1.18 /usr/local/bin/k3s-agent-uninstall.sh
ssh clusteradm@10.0.1.17 /usr/local/bin/k3s-agent-uninstall.sh
ssh clusteradm@10.0.1.16 /usr/local/bin/k3s-agent-uninstall.sh
ssh clusteradm@10.0.1.15 /usr/local/bin/k3s-agent-uninstall.sh
ssh clusteradm@10.0.1.14 /usr/local/bin/k3s-agent-uninstall.sh
ssh clusteradm@10.0.1.13 /usr/local/bin/k3s-agent-uninstall.sh
ssh clusteradm@10.0.1.12 /usr/local/bin/k3s-uninstall.sh
ssh clusteradm@10.0.1.11 /usr/local/bin/k3s-uninstall.sh
ssh clusteradm@10.0.1.10 /usr/local/bin/k3s-uninstall.sh

rm ~/.kube/config