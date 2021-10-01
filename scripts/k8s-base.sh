#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo "System update"
apt-get update
apt-get upgrade -y
apt-get install -y apt-transport-https ca-certificates curl software-properties-common vim

#!/usr/bin/env bash

echo "Checking for: docker"
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' docker-ce|grep "install ok installed")
if [ "" == "$PKG_OK" ]; then
    echo "Installing docker"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(lsb_release -cs) stable"
    apt-get update
    apt-cache policy docker-ce
    apt-get install -y docker-ce
    systemctl enable docker
    systemctl status docker

    # run docker commands as vagrant user (sudo not required)
    apt-mark hold docker-ce

    usermod -aG docker vagrant
    mkdir -p /etc/systemd/system/docker.service.d

    # Setup daemon with MTU 1440 and systemd as cgroupdriver
    cat > /etc/docker/daemon.json <<EOF
{
  "mtu": 1440,
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
fi

echo "Checking for: kubeadm"

# kubelet requires swap off
swapoff -a
# keep swap off after reboot
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

PKG_OK=$(dpkg-query -W --showformat='${Status}\n' kubeadm|grep "install ok installed")
if [ "" == "$PKG_OK" ]; then
    echo "Installing kubeadm"
    # https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#installing-kubeadm-kubelet-and-kubectl
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
    echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
    apt-get update
    apt-get install -y kubeadm kubelet kubectl
    apt-mark hold kubelet kubeadm kubectl

    # set node-ip
    echo "Environment=\"KUBELET_EXTRA_ARGS=--node-ip=$K8S_VM_IP\"" | sudo tee -a /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
fi

systemctl daemon-reload
systemctl restart kubelet
systemctl restart docker

eoch 'Add kubectl bash autocomplete'
echo 'source <(kubectl completion bash)' >> /home/vagrant/.bashrc
