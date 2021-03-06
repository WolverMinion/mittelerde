#!/bin/bash
# Parameter:
# 1 - Master/node
# 2 - IP Master
# 3 - Kubernetes-version

set -eu

K8S_VERSION=$3
K8S_VERSION=${K8S_VERSION:-1.12.}
K8S_CNI_VERSION=${K8S_CNI_VERSION:-0.6.0-00}

#####
# Disable swap
#####
swapoff -a
sed -e 's-^\(.*swap.*\)-#\1-' -i /etc/fstab||true
swapon -s

#####
#Setup Kubernetes
#####
tee /etc/apt/preferences.d/k8s <<EOF
Package: kubeadm
Pin: version $K8S_VERSION*
Pin-Priority: 1000

Package: kubelet
Pin: version $K8S_VERSION*
Pin-Priority: 1000

Package: kubectl
Pin: version $K8S_VERSION*
Pin-Priority: 1000

Package: kubernetes-cni
Pin: version $K8S_CNI_VERSION
Pin-Priority: 1000

EOF

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo 'deb http://apt.kubernetes.io/ kubernetes-xenial main' | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update && apt-get install kubernetes-cni kubeadm kubelet kubectl -y 

systemctl enable kubelet

systemctl daemon-reload

case "${1}" in
        master)
            ADDRESS="$(ip -4 addr show eth0 | grep "inet" | head -1 |awk '{print $2}' | cut -d/ -f1)"

            echo Executing kubeadm init 
            kubeadm init --apiserver-advertise-address=${ADDRESS} --kubernetes-version "$K8S_VERSION"

            echo copy token
            kubeadm token create --print-join-command > /tmp/kubeadm_join
            
            echo copy kube-config...
            mkdir -p ~/.kube/
            cp /etc/kubernetes/admin.conf ~/.kube/config

            echo Deploying Network Layer

            MSG="Wating for Kubernets-API to get ready"
            COUNT=10
            DELAY=6
            COMMAND='kubectl get no'
            while eval $COMMAND 2> /dev/null ; [ $? -ne 0 -a $COUNT -gt 0 ];do
              sleep $DELAY
              COUNT=$(( $COUNT-1 ))
              echo $MSG - Counter: $COUNT
            done

            #  Network-Layer
            kubectl apply -f \
            "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
            #curl https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml| sed "s/amd64/arm/g" | kubectl create -f -           
            ;;

        node)
            bash /tmp/kubeadm_join
            ;;
esac
