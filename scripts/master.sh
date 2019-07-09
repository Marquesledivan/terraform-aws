#!/bin/bash

exec &> /var/log/init-aws-kubernetes-master.log

set -o verbose
set -o errexit
set -o pipefail


export KUBEADM_TOKEN=${kubeadm_token}
export IP_ADDRESS=$(ifconfig -a eth0 | grep -e "inet " | awk -F":" '{print $2}' | awk -F" " '{print $1}')
export KUBERNETES_VERSION="1.15.0"

# Set this only after setting the defaults
set -o nounset

# Installation kernel kubectl kubelet and kubeabm and update on the operating system

apt-get update -y && apt-get upgrade -y

curl -fsSL https://get.docker.com | bash

apt-get update && apt-get install -y apt-transport-https

apt-get install bash-completion -y

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list

apt-get update && apt-get install -y kubelet kubeadm kubectl

#Enabling systemd support

sed -i "s/cgroup-driver=systemd/cgroup-driver=cgroupfs/g" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

cat > /etc/modules-load.d/k8s.conf <<EOF
br_netfilter
ip_vs_rr
ip_vs_wrr
ip_vs_sh
nf_conntrack_ipv4
ip_vs
EOF

# Fix kubelet configuration
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

# Restart docker.
systemctl daemon-reload
systemctl restart docker
systemctl restart kubelet


# Set settings needed by Docker
sysctl net.bridge.bridge-nf-call-iptables=1
sysctl net.bridge.bridge-nf-call-ip6tables=1

# Initialize the master
# Initialize the master
cat >/tmp/kubeadm.yaml <<EOF
---
apiVersion: kubeadm.k8s.io/v1beta1
kind: InitConfiguration
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  token: $KUBEADM_TOKEN
  ttl: 0s
  usages:
  - signing
  - authentication
nodeRegistration:
  criSocket: /var/run/dockershim.sock
  name: $FULL_HOSTNAME
  taints:
  - effect: NoSchedule
    key: node-role.kubernetes.io/master
---
apiVersion: kubeadm.k8s.io/v1beta1
kind: ClusterConfiguration
apiServer:
  certSANs:
  - $IP_ADDRESS
  timeoutForControlPlane: 5m0s
certificatesDir: /etc/kubernetes/pki
clusterName: kubernetes
dns:
  type: CoreDNS
etcd:
  local:
    dataDir: /var/lib/etcd
imageRepository: k8s.gcr.io
kubernetesVersion: v$KUBERNETES_VERSION
networking:
  dnsDomain: cluster.local
  podSubnet: ""
  serviceSubnet: 10.96.0.0/12
EOF

kubeadm reset --force
kubeadm init --config /tmp/kubeadm.yaml

# Use the local kubectl config for further kubectl operations

export KUBECONFIG=/etc/kubernetes/admin.conf

# Install calico
kubectl apply -f /tmp/calico.yaml

# Configure kubectl
mkdir -p /root/.kube
sudo cp -i /etc/kubernetes/admin.conf /root/.kube/config
sudo chown $(id -u):$(id -g) /root/.kube/config

kubectl completion bash >/etc/bash_completion.d/kubectl

# Allow the user to administer the cluster
kubectl create clusterrolebinding admin-cluster-binding --clusterrole=cluster-admin --user=admin

# Prepare the kubectl config file for download to client (IP address)
export KUBECONFIG_OUTPUT=/root/kubeconfig_ip
kubeadm alpha kubeconfig user \
  --client-name admin \
  --apiserver-advertise-address $IP_ADDRESS \
  > $KUBECONFIG_OUTPUT
chown $(id -u):$(id -g) $KUBECONFIG_OUTPUT
chmod 0600 $KUBECONFIG_OUTPUT

cp /root/kubeconfig_ip /root/kubeconfig
sed -i "s/server: https:\/\/$IP_ADDRESS:6443/server: https:\/\/$IP_ADDRESS:6443/g" /root/kubeconfig
chown $(id -u):$(id -g) /root/kubeconfig
chmod 0600 /root/kubeconfig
